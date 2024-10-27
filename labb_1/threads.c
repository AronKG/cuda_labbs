#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

// Number of threads to create
#define NUM_THREADS 5

// Thread function, voide* alowing any type of data
void* printHello(void* threadId) {
long tid = (long)threadId; 
printf("Hello from thread #%ld\n", tid);
pthread_exit(NULL);// Terminate the thread
return NULL; // This line is typically not reached due to pthread_exit above.
}

int main() {
	pthread_t threads[NUM_THREADS]; 	// Declare an array to hold thread identifiers
	int rc;					// Variable to hold return code from pthread_create						
	for(long t = 0; t < NUM_THREADS; t++) {
	printf("Creating thread %ld\n", t);
	rc = pthread_create(&threads[t], NULL, printHello, (void*)t);
	if(rc) {
		printf("Error: Unable to create thread, %d\n", rc);
	exit(-1);
    }
  }
// Join the threads
  for(long t = 0; t < NUM_THREADS; t++) {
	pthread_join(threads[t], NULL);
   }
  printf("Main thread completing\n");
  return 0;
}
