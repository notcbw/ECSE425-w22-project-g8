Please use the "Base_Processor" project directory to test the unoptimized piplined processor.

Please use the "Cached_Processor" project directory to test the cache optimized pipelined processor. The "Cached_Processor" is mostly operational but has not been thoroughly tested unlike the "Base_Processor".

How to run the code:

1) Place the assembled program file into the project directory (the run.tcl file should be in that same directory)
2) Rename the program file to 'program.txt'
3) Open Modelsim, navigate to the project directory and run the command "source run.tcl"
4) After the simulation has been completed, the resultant register file and the data memory will be outputted in the same directory with filenames "register_file.txt" and "memory.txt" respectively.

Thanks.