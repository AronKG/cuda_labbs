#include <iostream>  // Include the standard input-output library
#include <math.h>    // Include math functions for checking errors

// CUDA kernel function to multiply elements of two arrays
__global__ void multKernel(int n, float* a, float* b, float* c) 
{ 
    // Calculate the global thread index
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    
    // Calculate the stride for accessing elements based on total threads in grid
    int stride = blockDim.x * gridDim.x;

    // Loop over array elements in strides so each thread processes multiple elements
    for (int i = index; i < n; i += stride) {
        c[i] = a[i] * b[i];  // Multiply elements of arrays 'a' and 'b' and store in 'c'
    }
}

int main() {
    int N = 1 << 24;  // Define the size of the arrays (2^24 elements)
    
    // Declare pointers for host arrays
    float *h_a, *h_b, *h_c;
    
    // Declare pointers for device arrays
    float *d_a, *d_b, *d_c;

    // Allocate memory for host arrays
    h_a = new float[N];
    h_b = new float[N];
    h_c = new float[N];

    // Allocate memory for device arrays on the GPU
    cudaMalloc(&d_a, N * sizeof(float));
    cudaMalloc(&d_b, N * sizeof(float));
    cudaMalloc(&d_c, N * sizeof(float));

    // Initialize the host arrays 'h_a' and 'h_b' with values
    for (int i = 0; i < N; i++) {
        h_a[i] = 2.0f;  // Set each element of 'h_a' to 2.0
        h_b[i] = 3.0f;  // Set each element of 'h_b' to 3.0
    }

    // Copy the initialized data from host arrays to device arrays
    cudaMemcpy(d_a, h_a, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, N * sizeof(float), cudaMemcpyHostToDevice);

    // Define the block size and calculate the number of blocks needed
    int blockSize = 256;  // Number of threads per block
    int numBlocks = (N + blockSize - 1) / blockSize;  // Total number of blocks

    // Launch the kernel with the specified number of blocks and threads per block
    multKernel<<<numBlocks, blockSize>>>(N, d_a, d_b, d_c);

    // Copy the result from device memory back to host memory
    cudaMemcpy(h_c, d_c, N * sizeof(float), cudaMemcpyDeviceToHost);

    // Check the result for any errors by comparing with the expected value (6.0f)
    float maxError = 0.0f;  // Variable to store the maximum error found
    for (int i = 0; i < N; i++) {
        maxError = fmax(maxError, fabs(h_c[i] - 6.0f));  // Calculate error and update maxError if needed
    }

    // Print the maximum error found in the results
    std::cout << "Max error: " << maxError << std::endl;

    // Free allocated device memory
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);

    // Free allocated host memory
    delete[] h_a;
    delete[] h_b;
    delete[] h_c;

    return 0;  // End of the program
}
