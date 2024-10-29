#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <arm_neon.h>    // Include ARM NEON library for SIMD operations
#include <pthread.h>     // Include pthread library for multithreading

// Define a struct to hold data for each thread's work
typedef struct {
    float* a;            // Pointer to array 'a'
    float* b;            // Pointer to array 'b'
    float* r;            // Pointer to result array 'r'
    int num;             // Number of elements to process
    int start;           // Start index for this thread's work
    int end;             // End index for this thread's work
} WorkType;

// Standard multiplication function for two float arrays, storing the result in 'r'
void mult_std(float* a, float* b, float* r, int num) {
    for (int i = 0; i < num; i++) {
        r[i] = a[i] * b[i];    // Multiply each element of 'a' and 'b'
    }
}

// SIMD vectorized multiplication function for higher performance on ARM processors
void mult_vect(float* a, float* b, float* r, int num) {
	
//float32x4_t is data type defined in ARM NEON,represents a 128-bit vector containing four 32-bit floating-point elements.
    float32x4_t va, vb, vr;     // Define NEON SIMD registers
    for (int i = 0; i < num; i += 4) { // Process four floats per loop
        va = vld1q_f32(&a[i]);        // Load four floats from 'a' into NEON register
        vb = vld1q_f32(&b[i]);        // Load four floats from 'b' into NEON register
        vr = vmulq_f32(va, vb);       // Perform SIMD multiplication of va and vb
        vst1q_f32(&r[i], vr);         // Store the result into 'r'
    }
}

// Function executed by each thread to perform standard multiplication on assigned work
void* work_thread(void *arg) {
    WorkType* work = (WorkType *)arg;    // Cast the argument to WorkType pointer
    mult_std(work->a, work->b, work->r, work->num);  // Call mult_std for this segment
}

int main(int argc, char *argv[]) {
    int num = 100000000;     // Total number of elements to process
    int num_threads = 4;     // Number of threads to use
    pthread_t threads[num_threads]; // Array to hold thread identifiers
    WorkType work_info[num_threads]; // Array of work structures for each thread

    // Allocate aligned memory for arrays to improve memory access efficiency
    float *a = (float*)aligned_alloc(16, num * sizeof(float));
    float *b = (float*)aligned_alloc(16, num * sizeof(float));
    float *r = (float*)aligned_alloc(16, num * sizeof(float));

    // Initialize arrays 'a' and 'b' with values based on their index
    for (int i = 0; i < num; i++) {
        a[i] = (i % 127) * 0.1457f;
        b[i] = (i % 331) * 0.1231f;
    }

    struct timespec ts_start;   // Start time for timing
    struct timespec ts_end_1;   // End time after mult_std for timing
    struct timespec ts_end_2;   // End time after mult_vect for timing

    clock_gettime(CLOCK_MONOTONIC, &ts_start); // Record start time for multithreaded version

    // Set up work for each thread and start them
    for (int i = 0; i < num_threads; i++) {
        work_info[i].a = &a[i * num / num_threads];   // Assign portion of 'a'
        work_info[i].b = &b[i * num / num_threads];   // Assign portion of 'b'
        work_info[i].r = &r[i * num / num_threads];   // Assign portion of 'r'
        work_info[i].num = num / num_threads;         // Number of elements for this thread
        work_info[i].start = i * (num / num_threads); // Start index for this thread
        work_info[i].end = (i + 1) * (num / num_threads); // End index for this thread

        // Create a thread to handle this work segment
        pthread_create(&threads[i], NULL, work_thread, &work_info[i]);
    }

    // Wait for each thread to complete its work
    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
    }

    clock_gettime(CLOCK_MONOTONIC, &ts_end_1); // Record time after multithreaded work is done

    // Perform standard multiplication across the entire array
    mult_std(a, b, r, num);
    clock_gettime(CLOCK_MONOTONIC, &ts_end_1); // Record time after mult_std completes

    // Perform SIMD vectorized multiplication across the entire array
    mult_vect(a, b, r, num);
    clock_gettime(CLOCK_MONOTONIC, &ts_end_2); // Record time after mult_vect completes

    // Calculate elapsed time for each multiplication method
    double duration_std = (ts_end_1.tv_sec - ts_start.tv_sec) +
                          (ts_end_1.tv_nsec - ts_start.tv_nsec) * 1e-9;
    double duration_vec = (ts_end_2.tv_sec - ts_end_1.tv_sec) +
                          (ts_end_2.tv_nsec - ts_end_1.tv_nsec) * 1e-9;

    // Print the elapsed time for each multiplication method
    printf("Elapsed time std: %f\n", duration_std);
    printf("Elapsed time vec: %f\n", duration_vec);

    // Free allocated memory
    free(a);
    free(b);
    free(r);
    return 0;
}
