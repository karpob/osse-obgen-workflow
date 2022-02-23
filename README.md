# osse-obgen-workflow
workflow scripting for osse observation generation
"workflow" is used really loosely here. This is really just a job that resubmits itself the same way GEOS-ADAS does right now. Really this should be broken up in to cylc tasks, but NCCS restrictions are unknown at the moment. Anyway to run it:
sbatch --export=MY_DTG='2006063000' genObs.j

Where MY_DTG is the start year/month/day/hour. 
