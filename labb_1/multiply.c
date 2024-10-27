#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <arm_neon.h>
#include <pthread.h>

typedef struct {
	float* a;
	float* b;
	float* r;
	int num;
        int start;
        int end;
} WorkType;


void mult_std(float* a, float* b, float* r, int num)
 {
	for (int i = 0; i < num; i++)
 {
 r[i] = a[i] * b[i];
 }
} 

void mult_vect(float* a, float* b, float* r, int num)
 {
 float32x4_t va, vb, vr;
 for (int i = 0; i < num; i +=4)
  {
        va = vld1q_f32(&a[i]);
	vb = vld1q_f32(&b[i]);
	vr = vmulq_f32(va, vb);
	vst1q_f32(&r[i], vr);
    }
} 

void* work_thread(void *arg) {
  WorkType* work = (WorkType *)arg;

	mult_std(work->a, work->b, work->r, work->num);

}


int main(int argc, char *argv[]) {

	int num = 100000000; // Total number of elements
	int num_threads = 4; // Number of threads
	pthread_t  threads[num_threads]; 
	WorkType work_info[num_threads]; 

	float *a = (float*)aligned_alloc(16, num*sizeof(float));
	float *b = (float*)aligned_alloc(16, num*sizeof(float));
	float *r = (float*)aligned_alloc(16, num*sizeof(float));

	//This loop initializes the input arrays a and b with some floating-point values.
	for (int i = 0; i < num; i++) 
	{
	  a[i] = (i % 127)*0.1457f;
	  b[i] = (i % 331)*0.1231f;
	}


	struct timespec ts_start;
	struct timespec ts_end_1;
	struct timespec ts_end_2;

	clock_gettime(CLOCK_MONOTONIC, &ts_start);

    for (int i = 0; i < num_threads; i++) {
        work_info[i].a = &a[i*num/num_threads];
        work_info[i].b = &b[i*num/num_threads];
        work_info[i].r = &r[i*num/num_threads];
        work_info[i].num = num/num_threads;
        work_info[i].start = i * (num / num_threads);
        work_info[i].end = (i + 1) * (num / num_threads);

        pthread_create(&threads[i], NULL, work_thread, &work_info[i]);
    }


    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
    }

    clock_gettime(CLOCK_MONOTONIC, &ts_end_1);


	mult_std(a, b, r, num);
	clock_gettime(CLOCK_MONOTONIC, &ts_end_1);
	mult_vect(a, b, r, num);
	clock_gettime(CLOCK_MONOTONIC, &ts_end_2);
	double duration_std = (ts_end_1.tv_sec - ts_start.tv_sec) +
		(ts_end_1.tv_nsec - ts_start.tv_nsec) * 1e-9;
	double duration_vec = (ts_end_2.tv_sec - ts_end_1.tv_sec) +
		(ts_end_2.tv_nsec - ts_end_1.tv_nsec) * 1e-9;

	printf("Elapsed time std: %f\n", duration_std);
	printf("Elapsed time vec: %f\n", duration_vec);

	free(a);
	free(b);
	free(r);
return 0;
}
