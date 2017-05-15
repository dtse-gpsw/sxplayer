from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import os
extensions = [
    Extension(
      "sxplayer_py", ["sxplayer_py.pyx"],
      libraries=["sxplayer", "avcodec", "avformat", "avfilter"],
      library_dirs=["../..", "/usr/local/lib"],
      include_dirs=["../.."])]

setup(
  name = 'sxplayer python',
  ext_modules = cythonize(extensions)#, gdb_debug=True)
)
