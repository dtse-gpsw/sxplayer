from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import os

has_source = os.path.isfile('sxplayer_py.c')

extensions = [
    Extension(
      "sxplayer_py", ["sxplayer_py.pyx" if not has_source else "sxplayer_py.c"],
      libraries=["sxplayer", "avcodec", "avformat", "avfilter"],
      library_dirs=["../..", "/usr/local/lib"],
      include_dirs=["../.."])]

setup(
  name = 'sxplayer python',
  ext_modules = cythonize(extensions) if not has_source else extensions#, gdb_debug=True)
)
