set(proj python-opencv)

# Set dependency list
set(${proj}_DEPENDENCIES python python-setuptools python-pip)

set(requirements_file ${CMAKE_BINARY_DIR}/${proj}-requirements.txt)
file(WRITE ${requirements_file} [===[
# Hashes correspond to the following packages:
# - opencv_contrib_python-4.2.0.32-cp36-cp36m-win_amd64.whl
# - opencv_contrib_python-4.2.0.32-cp36-cp36m-macosx_10_9_x86_64.whl
# - opencv_contrib_python-4.2.0.32-cp36-cp36m-manylinux1_x86_64.whl
opencv-contrib-python==4.2.0.32 --hash=sha256:91b29762634f20e3bafe7bc2c9361aeb48efb8bf8bf33f47d5985fea9fcad0cf \
                                --hash=sha256:59a80f0bbaee09dad0ff9800b22bcee9f9432a645e25be49922782ceb4500bfd \
                                --hash=sha256:564eec2471439ef7e5835a5c7ec4e379575cd2f115a3f4c67d8ae8078a47a7fd
]===])

if(NOT DEFINED Slicer_USE_SYSTEM_${proj})
  set(Slicer_USE_SYSTEM_${proj} ${Slicer_USE_SYSTEM_python})
endif()

# Include dependent projects if any
ExternalProject_Include_Dependencies(${proj} PROJECT_VAR proj DEPENDS_VAR ${proj}_DEPENDENCIES)

if(Slicer_USE_SYSTEM_${proj})
  foreach(module_name IN ITEMS opencv-contrib-python)
    ExternalProject_FindPythonPackage(
      MODULE_NAME "${module_name}"
      REQUIRED
      )
  endforeach()
endif()

if(NOT Slicer_USE_SYSTEM_${proj})

  ExternalProject_Add(${proj}
    ${${proj}_EP_ARGS}
    DOWNLOAD_COMMAND ""
    SOURCE_DIR ${CMAKE_BINARY_DIR}/${proj}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${PYTHON_EXECUTABLE} -m pip install --require-hashes -r ${requirements_file}
    LOG_INSTALL 1
    DEPENDS
      ${${proj}_DEPENDENCIES}
    )

  ExternalProject_GenerateProjectDescription_Step(${proj}
    VERSION ${_version}
    )

  #-----------------------------------------------------------------------------
  # Sanity checks

  foreach(varname IN ITEMS
      python_DIR
      PYTHON_SITE_PACKAGES_SUBDIR
      )
    if("${${varname}}" STREQUAL "")
      message(FATAL_ERROR "${varname} CMake variable is expected to be set")
    endif()
  endforeach()

  #-----------------------------------------------------------------------------
  # Launcher setting specific to build tree

  set(${proj}_LIBRARY_PATHS_LAUNCHER_BUILD
    ${python_DIR}/${PYTHON_SITE_PACKAGES_SUBDIR}/opencv_contrib_python/core
    ${python_DIR}/${PYTHON_SITE_PACKAGES_SUBDIR}/opencv_contrib_python/lib
    )
  mark_as_superbuild(
    VARS ${proj}_LIBRARY_PATHS_LAUNCHER_BUILD
    LABELS "LIBRARY_PATHS_LAUNCHER_BUILD"
    )

  #-----------------------------------------------------------------------------
  # Launcher setting specific to install tree

  set(${proj}_LIBRARY_PATHS_LAUNCHER_INSTALLED
    <APPLAUNCHER_SETTINGS_DIR>/../lib/Python/${PYTHON_SITE_PACKAGES_SUBDIR}/opencv-contrib-python/core
    <APPLAUNCHER_SETTINGS_DIR>/../lib/Python/${PYTHON_SITE_PACKAGES_SUBDIR}/opencv-contrib-python/lib
    )
  mark_as_superbuild(
    VARS ${proj}_LIBRARY_PATHS_LAUNCHER_INSTALLED
    LABELS "LIBRARY_PATHS_LAUNCHER_INSTALLED"
    )

else()
  ExternalProject_Add_Empty(${proj} DEPENDS ${${proj}_DEPENDENCIES})
endif()

