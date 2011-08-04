/*
 *    This file is part of CasADi.
 *
 *    CasADi -- A symbolic framework for dynamic optimization.
 *    Copyright (C) 2010 by Joel Andersson, Moritz Diehl, K.U.Leuven. All rights reserved.
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

#include "unary_op.hpp"
#include "mx_tools.hpp"
#include <vector>
#include <sstream>
#include "../stl_vector_tools.hpp"

using namespace std;

namespace CasADi{

UnaryOp::UnaryOp(Operation op, MX x) : op_(op){
  // Put a densifying node in between if necessary
  if(!casadi_math<double>::f00_is_zero[op_]){
    makeDense(x);
  }
  
  setDependencies(x);
  setSparsity(x->sparsity());
}

UnaryOp* UnaryOp::clone() const{
  return new UnaryOp(*this);
}

void UnaryOp::print(std::ostream &stream, const std::vector<std::string>& args) const{
  casadi_math<double>::print[op_](stream,args.at(0),"nan");
}

void UnaryOp::evaluate(const DMatrixPtrV& input, DMatrixPtrV& output, const DMatrixPtrVV& fwdSeed, DMatrixPtrVV& fwdSens, const DMatrixPtrVV& adjSeed, DMatrixPtrVV& adjSens){
  double nan = numeric_limits<double>::quiet_NaN();
  vector<double> &outputd = output[0]->data();
  const vector<double> &inputd = input[0]->data();
  int nfwd = fwdSens.size();
  int nadj = adjSeed.size();
  
  if(nfwd==0 && nadj==0){
    // No sensitivities
    for(int i=0; i<size(); ++i)
      casadi_math<double>::fun[op_](inputd[i],nan,outputd[i]);
    
  } else {
    // Sensitivities
    double tmp[2];  // temporary variable to hold value and partial derivatives of the function
    for(int i=0; i<size(); ++i){
      // Evaluate and get partial derivatives
      casadi_math<double>::fun[op_](inputd[i],nan,outputd[i]);
      casadi_math<double>::der[op_](inputd[i],nan,outputd[i],tmp);
      
      // Propagate forward seeds
      for(int d=0; d<nfwd; ++d){
        fwdSens[d][0]->data()[i] = tmp[0]*fwdSeed[d][0]->data()[i];
      }

      // Propagate adjoint seeds
      for(int d=0; d<nadj; ++d){
        adjSens[d][0]->data()[i] += adjSeed[d][0]->data()[i]*tmp[0];
      }
    }
  }
}

void UnaryOp::evaluateSX(const SXMatrixPtrV& input, SXMatrixPtrV& output, const SXMatrixPtrVV& fwdSeed, SXMatrixPtrVV& fwdSens, const SXMatrixPtrVV& adjSeed, SXMatrixPtrVV& adjSens){
  // Do the operation on all non-zero elements
  const vector<SX> &xd = input[0]->data();
  vector<SX> &od = output[0]->data();
  
  for(int el=0; el<size(); ++el){
    casadi_math<SX>::fun[op_](xd[el],0,od[el]);
  }
}

void UnaryOp::evaluateMX(const MXPtrV& input, MXPtrV& output, const MXPtrVV& fwdSeed, MXPtrVV& fwdSens, const MXPtrVV& adjSeed, MXPtrVV& adjSens, bool output_given){
  // Evaluate function
  MX dummy;   // Dummy second argument
  if(!output_given){
    casadi_math<MX>::fun[op_](*input[0],dummy,*output[0]);
  }

  // Number of forward directions
  int nfwd = fwdSens.size();
  int nadj = adjSeed.size();
  if(nfwd>0 || nadj>0){
    // Get partial derivatives
    MX pd[2];
    casadi_math<MX>::der[op_](*input[0],dummy,*output[0],pd);
    
    // Propagate forward seeds
    for(int d=0; d<nfwd; ++d){
      *fwdSens[d][0] = pd[0]*(*fwdSeed[d][0]);
    }
    
    // Propagate adjoint seeds
    for(int d=0; d<nadj; ++d){
      *adjSens[d][0] += pd[0]*(*adjSeed[d][0]);
    }
  }
}

void UnaryOp::propagateSparsity(const DMatrixPtrV& input, DMatrixPtrV& output){
  const bvec_t *inputd = get_bvec_t(input[0]->data());
  bvec_t *outputd = get_bvec_t(output[0]->data());
  copy(inputd,inputd+size(),outputd);
}

} // namespace CasADi

