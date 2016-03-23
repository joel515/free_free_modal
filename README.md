# Modal Analysis Sim App

This rails application is intended to be a web-based _Sim App_ that utilizes
ANSYS at the back end to determine the free-free modal frequencies and mode
shapes of imported CAD geometry.  The user will input the following:

  * Geometry (currently only IGES format)
  * Requested number of modes or frequency range to report
    * The first 6 rigid-body modes from the free-free analysis will be skipped.
  * Mesh size as a factor of characteristic length.

The app is intended to be a generalized front end for ANSYS as an Eigensolver.

Results will be presented quantitatively in table format based on the number of
requested modes. Additionally, plots will be generated through Paraview so that
mode shapes can be examined.

Requirements:
  * ANSYS Mechanical APDL v16.2
  * Paraview v.4.4.0
    - With OSMesa libraries for off-screen rendering.
    - See [here](http://www.paraview.org/Wiki/ParaView/ParaView_And_Mesa_3D)
      for build and install instructions.

Developed by [Joel Kopp](mailto:jkopp@mkei.org) for the [Milwaukee Institute]
(https://www.mkei.org).
