# Simple file to find MKL (if availible)
# This needs a lot of work to make it robust
INCLUDE( CheckCXXSourceCompiles )

# This policy insures that the CMAKE_EXE_LINKER_FLAGS of the calling project
# are used in the try_compile test cmake project.  Without this
# clean rpath builds with mkl aren't possible. I prefer not to work in an
# environment with lots of LD_LIBRARY_PATH and DYLD_LIBRARY_PATH polution
# so I think this needs to be set here. -- PWD
cmake_policy(SET CMP0056 NEW)

# not sure if we can count on always getting "Intel"
string(TOLOWER CMAKE_CXX_COMPILER_ID LCASE_CMAKE_CXX_COMPILER_ID)

if ( NOT LCASE_CXX_COMPILER_ID MATCHES "intel" )
  # if not intel and MKL_ROOT not set
  if (NOT MKL_ROOT)
    find_path(MKL_ROOT "mkl.h"
      HINTS "${MKLROOT} ${MKL_HOME} $ENV{MKLROOT} $ENV{MKL_ROOT} $ENV{MKL_HOME}")
    string(REPLACE "/include" "" MKL_ROOT ${MKL_ROOT})
  else (NOT MKL_ROOT AND (NOT LCASE_CXX_COMPILER_ID MATCHES "intel"))
    message (FATAL_ERROR "ENABLE_OUTSIDE_MKL is TRUE and mkl not found. Set MKL_ROOT." )
  endif (NOT MKL_ROOT AND (NOT LCASE_CXX_COMPILER_ID MATCHES "intel"))

  #Do we support ilp?
  set(MKL_FIND_LIB "libmkl_intel_lp64${CMAKE_SHARED_LIBRARY_SUFFIX}")
  set(SUFFIXES lib lib/intel64)
  find_path(MKL_LINK_DIRECTORIES name "${MKL_FIND_LIB}" HINTS ${MKL_ROOT}
    PATH_SUFFIXES ${SUFFIXES})
  if (MKL_LINK_DIRECTORIES-NOTFOUND)
    message(FATAL_ERROR "MKL_LINK_DIRECTORIES not set. ${MKL_FIND_LIB} "
      "not found in MKL_ROOT/(${SUFFIXES})")
  endif (MKL_LINK_DIRECTORIES-NOTFOUND)
  message("MKL_LINK_DIRECTORIES: ${MKL_LINK_DIRECTORIES}")
  set(SUFFIXES include)
  find_path(MKL_INCLUDE_DIRECTORIES name "mkl.h" HINTS ${MKL_ROOT}
    PATH_SUFFIXES ${SUFFIXES})
  if (MKL_INCLUDE_DIRECTORIES-NOTFOUND)
    message(FATAL_ERROR "MKL_INCLUDE_DIRECTORIES not set. "mkl.h" not found in MKL_ROOT/(${SUFFIXES})")
  endif (MKL_INCLUDE_DIRECTORIES-NOTFOUND)
  message("MKL_INCLUDE_DIRECTORIES: ${MKL_INCLUDE_DIRECTORIES}")
  set(MKL_FLAGS "-m64")
  set(MKL_LINKER_FLAGS "-L${MKL_LINK_DIRECTORIES} -Wl,-rpath,${MKL_LINK_DIRECTORIES}")
  set(MKL_FLAGS "-I${MKL_INCLUDE_DIRECTORIES}")
  set(MKL_LIBRARIES "-lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lpthread -lm -ldl")
else ( NOT LCASE_CXX_COMPILER_ID MATCHES "intel" )
  # this takes away build control for intel but is convenient
  set(MKL_FLAGS "-mkl")
  set(MKL_COMPILE_DEFINITIONS "-mkl")
endif (NOT LCASE_CXX_COMPILER_ID MATCHES "intel" )

# Protect against clobbering the main CMAKE_CXX_FLAGS
set( org_CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" )

# reordering openmp check until after mkl removed the need for this
# if ( CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin" AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang" )
#   string(REPLACE "-fopenmp" "" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
# endif ( CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin" AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang" )

# Check for mkl.h
FILE( WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src_mkl.cxx"
  "#include <iostream>\n #include <mkl.h>\n int main() { return 0; }\n" )
try_compile(HAVE_MKL ${CMAKE_BINARY_DIR}
  ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src_mkl.cxx
  CMAKE_FLAGS ${MKL_FLAGS}
  "-DINCLUDE_DIRECTORIES=${MKL_INCLUDE_DIRECTORIES} "
  "-DLINK_DIRECTORIES=${MKL_LINK_DIRECTORIES}"
  LINK_LIBRARIES "${MKL_LIBRARIES}"
  COMPILE_DEFINITIONS "${MKL_COMPILE_DEFINITIONS}"
  OUTPUT_VARIABLE MKL_OUT)

if ( NOT HAVE_MKL )
  MESSAGE( "${MKL_OUT}" )
endif ( NOT HAVE_MKL )

# Check for mkl_vml_functions.h
FILE( WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src_mkl_vml.cxx"
  "#include <iostream>\n #include <mkl_vml_functions.h>\n int main() { return 0; }\n" )
try_compile(HAVE_MKL_VML ${CMAKE_BINARY_DIR}
  ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src_mkl_vml.cxx
  CMAKE_FLAGS ${MKL_FLAGS}
  "-DINCLUDE_DIRECTORIES=${MKL_INCLUDE_DIRECTORIES} "
  "-DLINK_DIRECTORIES=${MKL_LINK_DIRECTORIES}"
  COMPILE_DEFINITIONS "${MKL_COMPILE_DEFINITIONS}"
  OUTPUT_VARIABLE MKL_OUT)

# Check for fftw3
FILE( WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src_mkl_fftw3.cxx"
  "#include <iostream>\n #include <fftw/fftw3.h>\n int main() { return 0; }\n" )
try_compile(HAVE_MKL_FFTW3 ${CMAKE_BINARY_DIR}
  ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src_mkl_fftw3.cxx
  CMAKE_FLAGS ${MKL_FLAGS}
  "-DINCLUDE_DIRECTORIES=${MKL_INCLUDE_DIRECTORIES} "
  "-DLINK_DIRECTORIES=${MKL_LINK_DIRECTORIES}"
  LINK_LIBRARIES "${MKL_LIBRARIES}"
  COMPILE_DEFINITIONS "${MKL_COMPILE_DEFINITIONS}"
  OUTPUT_VARIABLE MKL_OUT)

set( CMAKE_CXX_FLAGS "${org_CMAKE_CXX_FLAGS}" )

IF ( HAVE_MKL )
  SET( MKL_FOUND 1 )
  SET( MKL_FLAGS ${MKL_FLAGS} )
  IF ( HAVE_MKL_FFTW3 )
    FILE(WRITE "${CMAKE_CURRENT_BINARY_DIR}/include/fftw3.h" "#include <fftw/fftw3.h>\n" )
    INCLUDE_DIRECTORIES( "${CMAKE_CURRENT_BINARY_DIR}/include" )
  ENDIF()
  MESSAGE(STATUS "MKL found: HAVE_MKL=${HAVE_MKL}, HAVE_MKL_VML=${HAVE_MKL_VML}, HAVE_MKL_FFTW3=${HAVE_MKL_FFTW3}")
ELSE( HAVE_MKL )
  SET( MKL_FOUND 0 )
  SET( MKL_FLAGS )
  SET( MKL_LIBRARIES )
  SET( MKL_LINKER_FLAGS )
  MESSAGE("MKL not found") #I think this is more important than a STATUS
ENDIF( HAVE_MKL )
