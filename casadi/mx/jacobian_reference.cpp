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

#include "jacobian_reference.hpp"
#include "evaluation.hpp"
#include "../stl_vector_tools.hpp"
#include "../matrix/matrix_tools.hpp"

using namespace std;

namespace CasADi{

JacobianReference::JacobianReference(const MX& x, int iind) : iind_(iind){
  setDependencies(x);
  
  // Pass the sparsity
  setSparsity(getFunction().jacSparsity(iind_,getFunctionOutput()));
}

JacobianReference* JacobianReference::clone() const{
  return new JacobianReference(*this);
}

void JacobianReference::print(std::ostream &stream, const std::vector<std::string>& args) const{
  stream << args[0] << ".jac(" << iind_ <<  ")";
}

void JacobianReference::evaluate(const DMatrixPtrV& input, DMatrixPtrV& output, const DMatrixPtrVV& fwdSeed, DMatrixPtrVV& fwdSens, const DMatrixPtrVV& adjSeed, DMatrixPtrVV& adjSens){
  casadi_assert(0);
}

void JacobianReference::evaluateSX(const SXMatrixPtrV& input, SXMatrixPtrV& output, const SXMatrixPtrVV& fwdSeed, SXMatrixPtrVV& fwdSens, const SXMatrixPtrVV& adjSeed, SXMatrixPtrVV& adjSens){
  casadi_assert(0);
}

void JacobianReference::evaluateMX(const MXPtrV& input, MXPtrV& output, const MXPtrVV& fwdSeed, MXPtrVV& fwdSens, const MXPtrVV& adjSeed, MXPtrVV& adjSens, bool output_given){
  casadi_assert(0);
}

void JacobianReference::propagateSparsity(const DMatrixPtrV& input, DMatrixPtrV& output){
  casadi_assert(0);
}


FX& JacobianReference::getFunction(){ 
  return dep(0)->dep(0)->getFunction();
}

} // namespace CasADi
