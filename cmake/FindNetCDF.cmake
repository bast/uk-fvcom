#[==[
Code taken from https://github.com/geospace-code/nc4fortran with following license.
See also https://www.scivision.dev/cmake-find-netcdf4/

MIT License

Copyright (c) 2019 Michael Hirsch, Ph.D.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#]==]

# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
FindNetCDF
----------

Find NetCDF4 library

based on: https://github.com/Kitware/VTK/blob/master/CMake/FindNetCDF.cmake
in general, NetCDF requires C compiler even if only using Fortran

Imported targets
^^^^^^^^^^^^^^^^

This module defines the following :prop_tgt:`IMPORTED` target:

``NetCDF::NetCDF_C``
  NetCDF C / C++ libraries

``NetCDF::NetCDF_Fortran``
  NetCDF Fortran libraries

Result Variables
^^^^^^^^^^^^^^^^

This module defines the following variables:

``NetCDF_FOUND``
  NetCDF4 is found (also ``NetCDF_C_FOUND`` and ``NetCDF_Fortran_FOUND``)
``NetCDF_C_LIBRARIES`` and ``NetCDF_Fortran_LIBRARIES
  uncached list of libraries (using full path name) to link against
``NetCDF_C_INCLUDE_DIRS`` and ``NetCDF_Fortran_INCLUDE_DIRS``
  uncached list of libraries (using full path name) to include

Search details:

1. look for CMake-build config files (for C / C++ only)
2. CMake manual search optionally using pkg-config (this step always needed for Fortran, and for C if step 1 fails)

#]=======================================================================]

include(CheckSourceCompiles)

function(netcdf_c)

if(PkgConfig_FOUND AND NOT NetCDF_C_LIBRARY)
  pkg_search_module(pc_nc netcdf)
endif()

find_path(NetCDF_C_INCLUDE_DIR
  NAMES netcdf.h
  HINTS ${pc_nc_INCLUDE_DIRS}
  DOC "NetCDF C include directory")

if(NOT NetCDF_C_INCLUDE_DIR)
  return()
endif()

find_library(NetCDF_C_LIBRARY
  NAMES netcdf
  HINTS ${pc_nc_LIBRARY_DIRS} ${pc_nc_LIBDIR}
  DOC "NetCDF C library")

if(NOT NetCDF_C_LIBRARY)
  return()
endif()

set(CMAKE_REQUIRED_FLAGS)
set(CMAKE_REQUIRED_INCLUDES ${NetCDF_C_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${NetCDF_C_LIBRARY})

check_source_compiles(C
"#include <netcdf.h>
#include <stdio.h>

int main(void){
printf(\"%s\", nc_inq_libvers());
return 0;
}
" NetCDF_C_links)

if(NOT NetCDF_C_links)
  return()
endif()

set(NetCDF_C_FOUND true PARENT_SCOPE)
set(NetCDF_C_INCLUDE_DIR ${NetCDF_C_INCLUDE_DIR} PARENT_SCOPE)
set(NetCDF_C_LIBRARY ${NetCDF_C_LIBRARY} PARENT_SCOPE)

endfunction(netcdf_c)


function(netcdf_fortran)

if(PkgConfig_FOUND AND NOT NetCDF_Fortran_LIBRARY)
  pkg_search_module(pc_ncf netcdf-fortran netcdf)
endif()

find_path(NetCDF_Fortran_INCLUDE_DIR
NAMES netcdf.mod
HINTS ${NetCDF_C_INCLUDE_DIR} ${pc_ncf_INCLUDE_DIRS}
DOC "NetCDF Fortran Include"
)

if(NOT NetCDF_Fortran_INCLUDE_DIR)
  return()
endif()

cmake_path(GET NetCDF_C_LIBRARY PARENT_PATH NetCDF_LIBDIR)

find_library(NetCDF_Fortran_LIBRARY
NAMES netcdff
HINTS ${NetCDF_LIBDIR} ${pc_ncf_LIBRARY_DIRS} ${pc_ncf_LIBDIR}
DOC "NetCDF Fortran library"
)

if(NOT NetCDF_Fortran_LIBRARY)
  return()
endif()

set(CMAKE_REQUIRED_FLAGS)
set(CMAKE_REQUIRED_INCLUDES ${NetCDF_Fortran_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${NetCDF_Fortran_LIBRARY})

check_source_compiles(Fortran "use netcdf; end" NetCDF_Fortran_links)

if(NOT NetCDF_Fortran_links)
  return()
endif()

set(NetCDF_Fortran_FOUND true PARENT_SCOPE)
set(NetCDF_Fortran_INCLUDE_DIR ${NetCDF_Fortran_INCLUDE_DIR} PARENT_SCOPE)
set(NetCDF_Fortran_LIBRARY ${NetCDF_Fortran_LIBRARY} PARENT_SCOPE)

endfunction(netcdf_fortran)

#============================================================
# main program

# 1. CMake-built NetCDF.
find_package(netCDF CONFIG QUIET)
if(netCDF_FOUND)
  set(NetCDF_C_FOUND "${netCDF_FOUND}")
  set(NetCDF_C_INCLUDE_DIR "${netCDF_INCLUDE_DIR}")
  set(NetCDF_C_LIBRARY "${netCDF_LIBRARIES}")
  set(NetCDF_VERSION "${NetCDFVersion}")
endif(netCDF_FOUND)

# 2. manual search for Fortran (and C if needed) using optional pkg-config
find_package(PkgConfig)
if(NOT NetCDF_C_FOUND)
  netcdf_c()
endif()
set(_ncdf_req ${NetCDF_C_LIBRARY})

if(Fortran IN_LIST NetCDF_FIND_COMPONENTS)
  netcdf_fortran()
  list(APPEND _ncdf_req ${NetCDF_Fortran_LIBRARY})
endif()

set(CMAKE_REQUIRED_FLAGS)
set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES)

mark_as_advanced(NetCDF_C_INCLUDE_DIR NetCDF_Fortran_INCLUDE_DIR NetCDF_C_LIBRARY NetCDF_Fortran_LIBRARY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(NetCDF
REQUIRED_VARS _ncdf_req
VERSION_VAR NetCDF_VERSION
HANDLE_COMPONENTS
HANDLE_VERSION_RANGE
)

if(NetCDF_FOUND)
  set(NetCDF_C_INCLUDE_DIRS ${NetCDF_C_INCLUDE_DIR})
  set(NetCDF_C_LIBRARIES ${NetCDF_C_LIBRARY})

  if(NOT TARGET NetCDF::NetCDF_C)
    add_library(NetCDF::NetCDF_C INTERFACE IMPORTED)
    set_target_properties(NetCDF::NetCDF_C PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${NetCDF_C_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "${NetCDF_C_LIBRARY}"
    )
  endif()

  if(NetCDF_Fortran_FOUND)
    set(NetCDF_Fortran_INCLUDE_DIRS ${NetCDF_Fortran_INCLUDE_DIR})
    set(NetCDF_Fortran_LIBRARIES ${NetCDF_Fortran_LIBRARY})
    if(NOT TARGET NetCDF::NetCDF_Fortran)
      add_library(NetCDF::NetCDF_Fortran INTERFACE IMPORTED)
      set_target_properties(NetCDF::NetCDF_Fortran PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${NetCDF_Fortran_INCLUDE_DIR}"
      INTERFACE_LINK_LIBRARIES "${NetCDF_Fortran_LIBRARY}"
      )
      target_link_libraries(NetCDF::NetCDF_Fortran INTERFACE NetCDF::NetCDF_C)
    endif()
  endif()


endif()