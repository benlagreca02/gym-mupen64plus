from setuptools import setup

# removed version so it just gets the latest
setup(name='gym_mupen64plus',
      install_requires=['gym',
                        'numpy',
                        'PyYAML',
                        'termcolor',
                        'mss',
                        'opencv-python'])
