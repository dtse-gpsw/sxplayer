from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import os
extensions = [
    Extension(
      "sxplayer_py", ["sxplayer_py.pyx"],
      libraries=["sxplayer"],
      library_dirs=[os.getcwd()])]

setup(
  name = 'sxplayer python',
  ext_modules = cythonize(extensions)#, gdb_debug=True)
)
