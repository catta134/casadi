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

#include "multiple_output.hpp"
#include "../fx/fx_internal.hpp"
#include "../stl_vector_tools.hpp"
#include "jacobian_reference.hpp"

using namespace std;

namespace CasADi{

MultipleOutput::MultipleOutput(){
}

MultipleOutput::~MultipleOutput(){
}

OutputNode::OutputNode(const MX& parent, int oind) : oind_(oind){
  setDependencies(parent);
  
  // Save the sparsity pattern
  setSparsity(dep(0)->sparsity(oind));
}

OutputNode::~OutputNode(){
}

void OutputNode::evaluate(const DMatrixPtrV& input, DMatrixPtrV& output, const DMatrixPtrVV& fwdSeed, DMatrixPtrVV& fwdSens, const DMatrixPtrVV& adjSeed, DMatrixPtrVV& adjSens){
}

void OutputNode::evaluateSX(const SXMatrixPtrV& input, SXMatrixPtrV& output, const SXMatrixPtrVV& fwdSeed, SXMatrixPtrVV& fwdSens, const SXMatrixPtrVV& adjSeed, SXMatrixPtrVV& adjSens){
}

void OutputNode::evaluateMX(const MXPtrV& input, MXPtrV& output, const MXPtrVV& fwdSeed, MXPtrVV& fwdSens, const MXPtrVV& adjSeed, MXPtrVV& adjSens, bool output_given){
}

void OutputNode::propagateSparsity(const DMatrixPtrV& input, DMatrixPtrV& output){ 
}

MX OutputNode::jac(int iind){
  return MX::create(new JacobianReference(MX::create(this),iind));
}

void OutputNode::print(std::ostream &stream, const std::vector<std::string>& args) const{
  stream << args[0] << "{" << oind_ <<  "}";
}



} // namespace CasADi
