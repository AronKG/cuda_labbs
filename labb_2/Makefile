
ex1: 
	nvcc ex1.cu -o ex1.out

prof-ex1:
	sudo nvprof --print-gpu-summary ./ex1.out

ex2:
	nvcc ex2.cu -o ex2.out
prof-ex2:
	sudo nvprof --print-gpu-summary ./ex2.out

ex3:
	nvcc ex3.cu -o ex3.out
prof-ex3:
	sudo nvprof --print-gpu-summary ./ex3.out

ex4: 
	nvcc ex4.cu -o ex4.out
prof-ex4:
	sudo nvprof --print-gpu-summary ./ex4.out

clean: 
	@rm *.out 

