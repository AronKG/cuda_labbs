#include <iostream>
#include <math.h>

// CUDA kernel to multiply two arrays
__global__ void multKernel(int n, float* a, float* b, float* c) {
    for (int i = 0; i < n; i++) {
        c[i] = a[i] * b[i]; // Perform element-wise multiplication
    }
}

int main() {
    int N = 1 << 24; // Define the size of the arrays (2^24 elements)
    float *h_a, *h_b, *h_c; // Host pointers
    float *d_a, *d_b, *d_c; // Device pointers

    // Allocate host memory
    h_a = new float[N]; // Host array A
    h_b = new float[N]; // Host array B
    h_c = new float[N]; // Host array C for results

    // Allocate device memory
    cudaMalloc(&d_a, N * sizeof(float)); // Device array A
    cudaMalloc(&d_b, N * sizeof(float)); // Device array B
    cudaMalloc(&d_c, N * sizeof(float)); // Device array C

    // Initialize host data
    for (int i = 0; i < N; i++) {
        h_a[i] = 2.0f; // Fill A with 2.0
        h_b[i] = 3.0f; // Fill B with 3.0
    }

    // Copy data from host to device
    cudaMemcpy(d_a, h_a, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, N * sizeof(float), cudaMemcpyHostToDevice);

    // Launch the kernel
    multKernel<<<1, 1>>>(N, d_a, d_b, d_c); // Execute kernel with 1 block of 1 thread

    // Copy result back to host
    cudaMemcpy(h_c, d_c, N * sizeof(float), cudaMemcpyDeviceToHost);

    // Check result for errors (all values should be 6.0f)
    float maxError = 0.0f; // Initialize max error
    for (int i = 0; i < N; i++)
        maxError = fmax(maxError, fabs(h_c[i] - 6.0f)); // Check max error from expected result

    std::cout << "Max error: " << maxError << std::endl; // Print max error

    // Clean up
    cudaFree(d_a); // Free device memory A
    cudaFree(d_b); // Free device memory B
    cudaFree(d_c); // Free device memory C
    delete[] h_a;  // Free host memory A
    delete[] h_b;  // Free host memory B
    delete[] h_c;  // Free host memory C

    return 0; // Return success
}
