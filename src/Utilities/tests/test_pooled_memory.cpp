/////////////////////////////////////////////////////////////////////////////////////
// This file is distributed under the University of Illinois/NCSA Open Source License.
// See LICENSE file in top directory for details.
//
// Copyright (c) 2017 Jeongnim Kim and QMCPACK developers.
//
// File developed by:  Mark Dewing, markdewing@gmail.com, University of Illinois at Urbana-Champaign
//
// File created by: Mark Dewing, markdewing@gmail.com, University of Illinois at Urbana-Champaign
//////////////////////////////////////////////////////////////////////////////////////


#include "catch.hpp"

#include "Utilities/PooledMemory.h"
#include <stdio.h>
#include <string>
#include <vector>
#include <random>
#include <complex>

using std::string;
using std::vector;
using std::complex;
namespace qmcplusplus {

TEST_CASE("pack scalar", "[utilities]")
{
  PooledMemory<double> p;
  int i0 = 1;
  long i1 = (1L << 31) - 1;
  float i2 = 0.33;
  double i3 = 0.23;
  complex<float> i4(0.23,0.33);
  complex<double> i5(0.33,0.23);
  std::vector<complex<double> > i6_dummy(3);
  std::vector<complex<double> > i6(3);
  i6[0] = complex<double>(0.23,0.33);
  i6[1] = complex<double>(0.33,0.23);
  i6[2] = complex<double>(0.56,0.65);

  p.add(i0);
  p.add(i1);
  p.add(i2);
  p.add(i3);
  p.add(i4);
  p.add(i5);
  p.add(i6_dummy.data(),i6_dummy.data()+i6_dummy.size());
  p.add(i6.data(),i6.data()+i6.size());

  p.allocate();
  p.rewind();

  p << i0;
  p << i1;
  p << i2;
  p << i3;
  p << i4;
  p << i5;
  p.put(i6_dummy.data(),i6_dummy.data()+i6_dummy.size());
  p.put(i6.data(),i6.data()+i6.size());

  p.rewind();
  int j0 = i0; i0 = 0;
  long j1 = i1; i1 = 0;
  float j2 = i2; i2 = 0;
  double j3 = i3; i3 = 0;
  complex<float> j4 = i4; i4 = 0;
  complex<double> j5 = i5; i5 = 0;
  std::vector<complex<double> > j6(i6);
  i6[0] = 0; i6[1] = 0; i6[2] = 0;
  p >> i0;
  p >> i1;
  p >> i2;
  p >> i3;
  p >> i4;
  p >> i5;

  p.get(i6_dummy.data(),i6_dummy.data()+i6_dummy.size());
  bool not_aligned = (((size_t) p.data())+p.current()) & (QMC_CLINE-1);
  REQUIRE(!not_aligned);

  p.get(i6.data(),i6.data()+i6.size());

  REQUIRE(i0==j0);
  REQUIRE(i1==j1);
  REQUIRE(i2==j2);
  REQUIRE(i3==j3);
  REQUIRE(i4==j4);
  REQUIRE(i5==j5);
  REQUIRE(i6[0]==i6[0]);
  REQUIRE(i6[1]==i6[1]);
  REQUIRE(i6[2]==i6[2]);
}

}
