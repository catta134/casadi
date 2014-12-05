/*
 *    This file is part of CasADi.
 *
 *    CasADi -- A symbolic framework for dynamic optimization.
 *    Copyright (C) 2010-2014 Joel Andersson, Joris Gillis, Moritz Diehl,
 *                            K.U. Leuven. All rights reserved.
 *    Copyright (C) 2011-2014 Greg Horn
 *
 *    CasADi is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 3 of the License, or (at your option) any later version.
 *
 *    CasADi is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with CasADi; if not, write to the Free Software
 *    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */


#ifndef SWIGXML
%include "typemaps.i"
#endif

/// Generic typemap structure
%inline %{

  /// Data structure in the target language holding data
#ifdef SWIGPYTHON
#define GUESTOBJECT PyObject
#elif defined(SWIGMATLAB)
#define GUESTOBJECT mxArray
#else
#define GUESTOBJECT void
#endif

  /// Check if Python object is of type T
  bool is_a(GUESTOBJECT *p, swig_type_info *type) {
#ifdef SWIGPYTHON
    if (p == Py_None) return false;
#endif
#ifdef SWIGMATLAB
    if (p == 0) return false;
#endif
    void *dummy = 0;
    return SWIG_ConvertPtr(p, &dummy, type, 0) >= 0;
  }

template<class T>
class meta {
  public:
    static swig_type_info** name;

    /// Convert Guest object to type T
    /// This function must work when is_a(GUESTOBJECT *p) too
    static int toCpp(GUESTOBJECT *p, T *m, swig_type_info *type) {
        T *t = 0;
        int res = swig::asptr(p, &t);
        if(SWIG_CheckState(res) && t) {
          if(m) *m=*t;
          if (SWIG_IsNewObj(res)) delete t;
          return true;
        } else {
          return false;
        }
    }
    /// Check if Guest object could ultimately be converted to type T
    /// may return true when is_a(GUESTOBJECT *p), but this is not required.
    static bool couldbe(GUESTOBJECT *p) {
        //int res = swig::asptr(p, (T**)(0));
        //if SWIG_CheckState(res) return true;
        T m;
        return toCpp(p, &m, *meta<T>::name);
    }
    
    // Vector specific stuff
    
    #ifdef SWIGPYTHON
    static bool couldbe_sequence(PyObject * p) {
      if(PySequence_Check(p)
         && !PyString_Check(p)
         && !is_a(p, *meta< casadi::SX >::name)
         && !is_a(p, *meta< casadi::MX >::name)
         && !is_a(p, *meta< casadi::Matrix<int> >::name)
         && !is_a(p, *meta< casadi::Matrix<double> >::name)
         && !PyObject_HasAttrString(p,"__DMatrix__")
         && !PyObject_HasAttrString(p,"__SX__")
         && !PyObject_HasAttrString(p,"__MX__")) {
        PyObject *it = PyObject_GetIter(p);
        if (!it) return false;
        PyObject *pe;
        while ((pe = PyIter_Next(it))) {                                // Iterate over the sequence inside the sequence
          if (!meta< T >::couldbe(pe)) {
            Py_DECREF(pe);Py_DECREF(it);return false;
          }
          Py_DECREF(pe);
        }
        Py_DECREF(it);
        if (PyErr_Occurred()) { PyErr_Clear(); return false; }
        return true;
      } else {
        return false;
      }
    }
    #endif // SWIGPYTHON
    
    // Assumes that p is a PYTHON sequence
    static int as_vector(GUESTOBJECT * p, std::vector<T> *m) {
#ifdef SWIGPYTHON
      if (PySequence_Check(p)
          && !PyString_Check(p)
          && !is_a(p, *meta< casadi::SX >::name)
          && !is_a(p, *meta< casadi::MX >::name)
          && !is_a(p, *meta< casadi::Matrix<int> >::name)
          && !is_a(p, *meta< casadi::Matrix<double> >::name)
          && !PyObject_HasAttrString(p,"__DMatrix__")
          && !PyObject_HasAttrString(p,"__SX__")
          && !PyObject_HasAttrString(p,"__MX__")) {
        PyObject *it = PyObject_GetIter(p);
        if (!it) { PyErr_Clear();  return false;}
        PyObject *pe;
        int size = PySequence_Size(p);
        if (size==-1) { PyErr_Clear();  return false;}
        m->resize(size);
        int i=0;
        while ((pe = PyIter_Next(it))) {
          // Iterate over the sequence inside the sequence
          if (!meta< T >::toCpp(pe, &(*m)[i++], *meta< T >::name)) {
            Py_DECREF(pe);
            Py_DECREF(it);
            return false;
          }
          Py_DECREF(pe);
        }
        Py_DECREF(it);
        return true;
      }
#endif // SWIGPYTHON
#ifdef SWIGMATLAB
      if (mxGetClassID(p)==mxCELL_CLASS && mxGetM(p)==1) {
        int sz = mxGetN(p);
        m->resize(sz);
        for (int i=0; i<sz; ++i) {
          GUESTOBJECT *pi = mxGetCell(p, i);
          if (pi==0 || !meta< T >::toCpp(pi, &(*m)[i], *meta< T >::name)) return false;
        }
        return true;
      }
#endif // SWIGMATLAB
      return false;
    }
};
%}

%define %my_generic_const_typemap(Precedence,Type...) 
%typemap(in) const Type & (Type m) {
  if (SWIG_ConvertPtr($input, (void **) &$1, $descriptor(Type*), 0) == -1) {
    if (!meta< Type >::toCpp($input, &m, $descriptor(Type*)))
      SWIG_exception_fail(SWIG_TypeError,"Input type conversion failure ($1_type)");
    $1 = &m;
  }
 }

%typemap(typecheck,precedence=Precedence) const Type & { $1 = is_a($input, $descriptor(Type *)) || meta< Type >::couldbe($input); }
%typemap(freearg) const Type  & {}

%enddef



#ifdef SWIGPYTHON

%define %my_creator_typemap(Precedence,Type...)

%typemap(in) Type {
  int res = SWIG_ConvertFunctionPtr($input, (void**)(&$1), $descriptor);
  if (!SWIG_IsOK(res)) {
    if (PyType_Check($input) && PyObject_HasAttrString($input,"creator")) {
      PyObject *c = PyObject_GetAttrString($input,"creator");
      res = SWIG_ConvertFunctionPtr(c, (void**)(&$1), $descriptor);
      Py_DECREF(c);
    }
    if (!SWIG_IsOK(res)) {
      %argument_fail(res,"$type",$symname, $argnum); 
    }
  }
}

%typemap(typecheck,precedence=Precedence) Type { 
  void *ptr = 0;
  int res = SWIG_ConvertFunctionPtr($input, &ptr, $descriptor);
  $1 = SWIG_CheckState(res);
  if (!$1 && PyType_Check($input) && PyObject_HasAttrString($input,"creator")) {
    PyObject *c = PyObject_GetAttrString($input,"creator");
    res = SWIG_ConvertFunctionPtr(c, &ptr, $descriptor);
    $1 = SWIG_CheckState(res);
    Py_DECREF(c);
  };
}
%enddef

#else // SWIGPYTHON
%define %my_creator_typemap(Precedence,Type...)
%enddef
#endif // SWIGPYTHON



// Create an output typemap for a const ref such that a copy is made
%define %outputConstRefCopy(Type)
%typemap(out) const Type & {
  $result = SWIG_NewPointerObj((new Type(*$1)), $descriptor(Type*), SWIG_POINTER_OWN |  0 );
}
%enddef

#ifdef SWIGPYTHON
%inline%{
// Indicates that self is derived from parent.
// by setting a special attribute __swigref_parent__
void PySetParent(PyObject* self, PyObject* parent) {
  Py_INCREF(parent);
  PyObject_SetAttrString(self,"__swigref_parent__",parent);
}

// Look for the __swigref_parent__ attribute and DECREF the parent if there is one
void PyDECREFParent(PyObject* self) {
  if (!PyObject_HasAttrString(self,"__swigref_parent__")) return;
  
  PyObject* parent = PyObject_GetAttrString(self,"__swigref_parent__");
  if (!parent) return;
  Py_DECREF(parent); // Once for PyObject_GetAttrString
  if (!parent) return;
  if (parent!=Py_None) {
    Py_DECREF(parent); // Once for the actual DECREF
  }
}

%}
#endif //SWIGPYTHON

// Create an output typemap for a ref such that ownership is implied
// The following text is obsolete:
// We make use of SWIG_POINTER_OWN to ensure that the "delete_*" routine is called, where we have put another hook via %unrefobject.
// We do not really imply that this SWIG objects owns the pointer
// We are actually abusing the term SWIG_POINTER_OWN: a non-const ref is usually created with SWIG_NewPointerObj(..., 0 |  0 )
%define %outputRefOwn(Type)
%typemap(out) Type & {
  $result = SWIG_NewPointerObj($1, $descriptor(Type*), 0 |  0 );
  PySetParent($result, obj0);
}
%typemap(out) const Type & {
   $result = swig::from(static_cast< Type * >($1));
   PySetParent($result, obj0);
}
%extend Type {
%pythoncode%{
    def __del__(self):
      if not(_casadi is None):
         _casadi.PyDECREFParent(self)

%}

}
%enddef

// Convert reference output to a new data structure
%define %outputRefNew(Type)
%typemap(out) Type & {
   $result = swig::from(static_cast< Type >(*$1));
}
%typemap(out) const Type & {
   $result = swig::from(static_cast< Type >(*$1));
}
%extend Type {
%pythoncode%{
    def __del__(self):
      if not(_casadi is None):
         _casadi.PyDECREFParent(self)

%}

}
%enddef

%inline %{
/// std::vector< Type >
#define meta_vector(Type) \
template <> \
int meta< std::vector< Type > >::toCpp(GUESTOBJECT *p, std::vector< Type > *m, swig_type_info *type) { \
  if (is_a(p, type)) {\
    std::vector< Type > *mp; \
    if (SWIG_ConvertPtr(p, (void **) &mp, type, 0) == -1) \
      return false; \
    if(m) *m=*mp;    \
    return true; \
  } \
  return meta< Type >::as_vector(p, m); \
} \

%}


#ifdef SWIGPYTHON
%inline%{
/** Check PyObjects by class name */
bool PyObjectHasClassName(PyObject* p, const char * name) {
  PyObject * classo = PyObject_GetAttrString( p, "__class__");
  PyObject * classname = PyObject_GetAttrString( classo, "__name__");
  
  bool ret = strcmp(PyString_AsString(classname),name)==0;
  Py_DECREF(classo);Py_DECREF(classname);
	return ret;
}

%}
#endif // SWIGPYTHON

%{
#define SWIG_Error_return(code, msg)  { std::cerr << "Error occured in CasADi SWIG interface code:" << std::endl << "  "<< msg << std::endl;SWIG_Error(code, msg); return 0; }
%}