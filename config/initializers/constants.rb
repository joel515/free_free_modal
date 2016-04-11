MAX_PPN =      16
MAX_NODE =     32
PARAVIEW_EXE = "/gpfs/home/jkopp/apps/paraview/4.4.0/bin/pvbatch"
MPI_EXE =      "mpirun"

GRAVITY = 9.80665

METHODS = {
  lanb:   "Block Lanczos",
  lanpcg: "PCG Lanczos",
  snode:  "Supernode modal solver",
  subsp:  "Subspace algorithm",
  unsym:  "Unsymmetric matrix",
  damp:   "Damped system",
  qrdamp: "Damped system-QR algorithm",
  vt:     "Variational Technology"
}

DIMENSIONAL_UNITS = {
  m:  { convert: 1,      text: "m" },
  mm: { convert: 0.001,  text: "mm" },
  cm: { convert: 0.01,   text: "cm" },
  in: { convert: 0.0254, text: "in" },
  ft: { convert: 0.3048, text: "ft" }
}

FORCE_UNITS = {
  n:   { convert: 1,                    text: "N" },
  kn:  { convert: 1000,                 text: "kN" },
  kgf: { convert: GRAVITY,              text: "kgf" },
  lbf: { convert: 4.448221615255,       text: "lbf" },
  kip: { convert: 4448.221615255,       text: "kip" }
}

STRESS_UNITS = {
  pa:  { convert: 1,               text: "Pa" },
  ba:  { convert: 0.1,             text: "Ba" },
  mpa: { convert: 1e6,             text: "MPa" },
  gpa: { convert: 1e9,             text: "GPa" },
  psf: { convert: 47.8802415938,   text: "psf" },
  psi: { convert: 6894.7547895096, text: "psi" }
}

DENSITY_UNITS = {
  kgm3:     { convert: 1,                text: "kg/m&sup3;".html_safe },
  tonnemm3: { convert: 1e12,             text: "tonne/mm&sup3;".html_safe },
  gcm3:     { convert: 1000,             text: "gm/cm&sup3;".html_safe },
  slugft3:  { convert: 515.3788206107,   text: "slug/ft&sup3;".html_safe },
  lbfs2in4: { convert: 10686895.2241841, text: "lbf-s&sup2;/in&sup4;".html_safe }
}

INERTIA_UNITS = {
  m4:  { convert: 1,         text: "m<sup>4</sup>".html_safe },
  mm4: { convert: 0.001**4,  text: "mm<sup>4</sup>".html_safe },
  in4: { convert: 0.0254**4, text: "in<sup>4</sup>".html_safe }
}

MASS_UNITS = {
  kg:  { convert: 1,           text: "kg" },
  lbm: { convert: 1 / 2.20462, text: "lbm" }
}

TORQUE_UNITS = {
  nm:   { convert: 1,                       text: "N-m" },
  nmm:  { convert: 0.001,                   text: "N-mm" },
  inlb: { convert: 4.448221615255 * 0.0254, text: "in-lbf" },
  ftlb: { convert: 4.448221615255 * 0.3048, text: "ft-lbf" }
}

UNIT_DESIGNATION = {
  name:     nil,
  length:   DIMENSIONAL_UNITS,
  width:    DIMENSIONAL_UNITS,
  height:   DIMENSIONAL_UNITS,
  meshsize: DIMENSIONAL_UNITS,
  modulus:  STRESS_UNITS,
  poisson:  nil,
  density:  DENSITY_UNITS,
  material: nil,
  load:     FORCE_UNITS,
  inertia:  INERTIA_UNITS,
  mass:     MASS_UNITS,
  torque:   TORQUE_UNITS
}

INPUT_UNITS = {
  si: { length: DIMENSIONAL_UNITS[:m],
        modulus: STRESS_UNITS[:pa],
        density: DENSITY_UNITS[:kgm3],
        text: "International" },
  cgs: { length: DIMENSIONAL_UNITS[:cm],
         modulus: STRESS_UNITS[:ba],
         density: DENSITY_UNITS[:gcm3],
         text: "CGS" },
  mpa: { length: DIMENSIONAL_UNITS[:mm],
         modulus: STRESS_UNITS[:mpa],
         density: DENSITY_UNITS[:tonnemm3],
         text: "MPa" },
  usf: { length: DIMENSIONAL_UNITS[:ft],
         modulus: STRESS_UNITS[:psf],
         density: DENSITY_UNITS[:slugft3],
         text: "US Customary (feet)" },
  usi: { length: DIMENSIONAL_UNITS[:in],
         modulus: STRESS_UNITS[:psi],
         density: DENSITY_UNITS[:lbfs2in4],
         text: "US Customary (inches)" }
}

RESULT_UNITS = {
  metric_mpa:   { displ:            DIMENSIONAL_UNITS[:mm],
                  displ_fem:        DIMENSIONAL_UNITS[:mm],
                  stress:           STRESS_UNITS[:mpa],
                  stress_fem:       STRESS_UNITS[:mpa],
                  force_reaction:   FORCE_UNITS[:n],
                  inertia:          INERTIA_UNITS[:mm4],
                  mass:             MASS_UNITS[:kg],
                  moment_reaction:  TORQUE_UNITS[:nmm],
                  text:             "Metric (MPa)" },
  metric_pa:    { displ:            DIMENSIONAL_UNITS[:m],
                  displ_fem:        DIMENSIONAL_UNITS[:m],
                  stress:           STRESS_UNITS[:pa],
                  stress_fem:       STRESS_UNITS[:pa],
                  force_reaction:   FORCE_UNITS[:n],
                  inertia:          INERTIA_UNITS[:m4],
                  mass:             MASS_UNITS[:kg],
                  moment_reaction:  TORQUE_UNITS[:nm],
                  text:             "Metric (Pa)" },
  imperial_psi: { displ:            DIMENSIONAL_UNITS[:in],
                  displ_fem:        DIMENSIONAL_UNITS[:in],
                  stress:           STRESS_UNITS[:psi],
                  stress_fem:       STRESS_UNITS[:psi],
                  force_reaction:   FORCE_UNITS[:lbf],
                  inertia:          INERTIA_UNITS[:in4],
                  mass:             MASS_UNITS[:lbm],
                  moment_reaction:  TORQUE_UNITS[:inlb],
                  text:             "Imperial (psi)" },
  imperial_ksi: { displ:            DIMENSIONAL_UNITS[:in],
                  displ_fem:        DIMENSIONAL_UNITS[:in],
                  stress:           STRESS_UNITS[:ksi],
                  stress_fem:       STRESS_UNITS[:ksi],
                  force_reaction:   FORCE_UNITS[:kip],
                  inertia:          INERTIA_UNITS[:in4],
                  mass:             MASS_UNITS[:lbm],
                  moment_reaction:  TORQUE_UNITS[:ftlb],
                  text:             "Imperial (ksi)" }
}
