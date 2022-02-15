# Intro
This is the code to reproduce the results of the paper "Simplified dynamic inflow for control engineering models" (https://www.eventure-online.com/parthen-uploads/7/22005/add_660443_393f0d76-aa2c-4345-bfdd-a64610c8252a.pdf, preprint).

# Prerequisites
In order to run this code you need:
* the OpenFAST MATLAB toolbox (https://github.com/OpenFAST/matlab-toolbox) on your MATLAB path
* the MATLAB Optimization toolbox
* the OpenFAST, turbsim and aerodyn_driver programs version 2.5.0
* OpenFAST must be accessible on your system path as "openfast"
* turbsim must be accessible on your system path as "turbsim"
* the path to aerodyn_driver must be set as an environment variable in MATLAB (e.g. ``setenv('AD_DRIVER', '~/OpenFAST/build/modules/aerodyn/aerodyn_driver')``)
* the DISCON.dll OpenFAST controller in the ``example_data/sim`` directory
* run the OpenFAST reference simulations by either calling ``coh`` in the ``example_data/wind`` and the ``example_data/sim`` directory or ``make`` in the ``example_data/sim`` directory

# Reproduce plots from paper
Run the ``run_all`` in the ``plot_for_paper`` directory.

Beware:
* The call to ``allStepsFromNeighboursAD`` will take a looong time execute but it will produce intermediate result files, so you can interrupt and continue later.
* The call to ``plot_result_sim_paper`` will also take very long but it will also produce intermediate result files.

