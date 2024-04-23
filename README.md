# MONAN - Model for Ocean-laNd-Atmosphere PredictioN

### *Pre-operational tests for MONAN with GFS at Egeon*

This folder aims to create a pre-operations version for testing MONAN with GFS at Egeon.

## History:



v0.1.0 - Initial revision



### Implementation at Egeon:

**Getting the scritps:**

Cloning this repo: `git clone https://github.com/monanadmin/scripts_CD-CT.git`
you will get this directories:
~~~
datain/namelists
scripts
~~~

- The `datain/namelists` directory contains all versioned namelists needded for run and compile all phases of model;
- The `scripts` directory is the most important folder that contains all the scripts that you will need to install, compile, run, and produce produtcs of the A-MONAN model.


You will need to execute only 6 steps scripts, so you can run the Atmospheric MONAN Model:


**1. Install the model:**

- First you need to get a **fork repository** in your github account of a MONAN oficial repo: `https://github.com/monanadmin/monan.git`
- The you can install the model in your work directory by running:

~~~
1.install_monan.bash <https://github.com/MYUSER/MONAN-Model.git>
~~~

- This first step will create a standart diretories structures for work:
~~~
scripts_CD-CT/
       scripts
       sources
       execs
       datain
       dataout
~~~

Where:
- `scripts` folder will contain all scripts produced to run all steps of the model;
- `sources` folder will contain all codes of any processes that uses compiled programming languages, such as MONAN model sources, convert_mpas sources, etc.
- `execs` folder will contain all the executables needed;
- `datain` folder will contain all the input data that the model need to run;
- `dataout` folder will contain all the output files generated of running of the MONAN, such as:
     - `dataout\Pre\<YYYYMMDDHH>` will contain all the output files from the pre-processing phase, mostly are all the initial condition for run the MONAN;
     - `dataout\Model\<YYYYMMDDHH>` will contain all the output files from the MONAN model;
     - `dataout\Post\<YYYYMMDDHH>` will contain all the output files from the post-processing phase of the MONAN;
     - `dataout\Prods\<YYYYMMDDHH>` will contain all the output files from the products generated, graphics, derivated variables, peace of domain, etc.

After running the first step, it will clone the MONAN model from your fork repo in a `source` diretory.


**2. Prepare the Initial Conditions for the model:**

- Just run the second script as follows:

~~~
2.pre_processing.bash EXP_NAME RESOLUTION LABELI FCST

EXP_NAME    :: Forcing: GFS
            :: Others options to be added later...
RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)
LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100
FCST        :: Forecast hours, e.g.: 24 or 36, etc.

24 hour forcast example:
./2.pre_processing.bash GFS 1024002 2024010100 24
~~~

**3. Run the model:**

- Execute the 3rd step script:

~~~
3.run_model.bash EXP_NAME RESOLUTION LABELI FCST

EXP_NAME    :: Forcing: GFS
            :: Others options to be added later...
RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)
LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100
FCST        :: Forecast hours, e.g.: 24 or 36, etc.

24 hour forcast example:
./3.run_model.bash GFS 1024002 2024010100 24
~~~

**4. Run the post-processing model:**

- Execute the 4th step script:

~~~
4.run_post.bash EXP_NAME RESOLUTION LABELI FCST

EXP_NAME    :: Forcing: GFS
            :: Others options to be added later...
RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)
LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100
FCST        :: Forecast hours, e.g.: 24 or 36, etc.

24 hour forcast example:
./4.run_post.bash GFS 1024002 2024010100 24
~~~

**5. Run ate least one single simple precipitation forecast figure example:**

- Execute the 5th step script:

~~~
5.run_products.bash EXP_NAME RESOLUTION LABELI FCST

EXP_NAME    :: Forcing: GFS
            :: Others options to be added later...
RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)
LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100
FCST        :: Forecast hours, e.g.: 24 or 36, etc.

24 hour forcast example:
./5.run_products.bash GFS 1024002 2024010100 24
~~~
