#include <jetson-utils/videoSource.h>  // Library for video input
#include <jetson-utils/videoOutput.h>  // Library for video output
#include <stdio.h> 

// Kernel to convert an RGB image to grayscale
__global__ void rgb2grayKernel(uchar4* image, uchar4* output, int width, int height)
{ 
    long int size = width * height;  // Total number of pixels
    int index = blockIdx.x * blockDim.x + threadIdx.x;  // Calculate unique index for each thread
    int stride = blockDim.x * gridDim.x;  // Define stride for parallel processing

    // Each thread processes pixels in strides to cover the whole image
    for (int i = index; i < size; i += stride) {
        // Grayscale formula using luminance coefficients for RGB channels
        unsigned char gray = (0.299 * image[i].x) + (0.587 * image[i].y) + (0.114 * image[i].z);
        output[i].x = gray;  // Set red channel to grayscale value
        output[i].y = gray;  // Set green channel to grayscale value
        output[i].z = gray;  // Set blue channel to grayscale value
    }
}

// Kernel to calculate the histogram of the grayscale image
__global__ void calcHistogramKernel(uchar4* d_output, int* histogram, int width, int height)
{ 
    long int size = width * height;  // Total number of pixels
    int index = blockIdx.x * blockDim.x + threadIdx.x;  // Unique index for each thread
    int stride = blockDim.x * gridDim.x;  // Define stride for parallel processing

    // Initialize histogram bins to 0 (only the first 256 threads do this)
    if(index < 256) {
        histogram[index] = 0; 
    }
    __syncthreads();  // Ensure all threads have finished initialization

    // Each thread processes pixels in strides to cover the whole image
    for (int i = index; i < size; i += stride) {
        unsigned char gray = d_output[i].x;  // Access the grayscale value
        atomicAdd(&histogram[gray], 1);  // Use atomic addition to avoid race conditions
    }
}

// Kernel to plot the histogram as a bar graph on the image
__global__ void plotHistogramKernel(uchar4* image, int* histogram, int width, int height, int max_freq)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;  // Unique index for each thread
    uchar4 white_pixel = make_uchar4(255, 255, 255, 255);  // Define white color for bars
    uchar4 black_pixel = make_uchar4(0, 0, 0, 255);  // Define black color for background

    if (index < 256) {  // Only the first 256 threads plot the histogram
        int freq = histogram[index] * 256 / max_freq;  // Scale frequency to fit graph height

        // Draw each bar of the histogram
        for (int i = 0; i < 256; i++) {
            int row = height - i - 1;  // Start from the bottom of the image
            if (i <= freq) {
                // Set pixels to white for the histogram bar
                image[row * width + 2 * index] = white_pixel;
                image[row * width + 2 * index + 1] = white_pixel;
            } else {
                // Set pixels to black for the background
                image[row * width + 2 * index] = black_pixel;
                image[row * width + 2 * index + 1] = black_pixel;
            }
        }
    }
}

int main(int argc, char** argv)
{
    int max_freq = 20000;  // Maximum frequency for histogram scaling

    // Create input and output streams for video
    videoSource* input = videoSource::Create(argc, argv, ARG_POSITION(0));  // Video input source
    videoOutput* output = videoOutput::Create(argc, argv, ARG_POSITION(1));  // Video output for original frame
    videoOutput* output2 = videoOutput::Create(argc, argv, ARG_POSITION(1));  // Video output for grayscale and histogram

    if (!input) return 0;  // Exit if input source is not created

    // Allocate memory for grayscale output on the GPU
    uchar4* d_output;
    size_t imageSize = input->GetWidth() * input->GetHeight() * sizeof(uchar4);
    cudaMalloc((void**)&d_output, imageSize);

    // Allocate memory for histogram on the GPU
    int* histogram; 
    cudaMalloc(&histogram, 256 * sizeof(int));
    int host_histo[256];  // Host array to store histogram results

    // Capture and display loop
    while (true) {
        uchar4* image = NULL;  // Pointer for the captured frame
        int status = 0;  // Status for video capture
        if (!input->Capture(&image, 1000, &status)) {  // Capture frame with 1000 ms timeout
            if (status == videoSource::TIMEOUT) continue;  // Skip if timeout
            break;  // Exit if end of stream (EOS)
        }

        // Launch kernel to convert image to grayscale
        rgb2grayKernel<<<16, 1024>>>(image, d_output, input->GetWidth(), input->GetHeight());

        // Launch kernel to calculate the histogram
        calcHistogramKernel<<<16, 1024>>>(d_output, histogram, input->GetWidth(), input->GetHeight());

        // Launch kernel to plot histogram on grayscale image
        plotHistogramKernel<<<1, 256>>>(d_output, histogram, input->GetWidth(), input->GetHeight(), max_freq);

        // Copy histogram data from device to host
        cudaMemcpy(host_histo, histogram, 256 * sizeof(int), cudaMemcpyDeviceToHost);

        // Sum the histogram values and print to console
        int sum = 0; 
        for (int i = 0; i < 256 ; i++) {
            sum += host_histo[i]; 
        }
        printf("%d\n", sum); 

        // Render original frame if output stream exists
        if (output != NULL) {
            output->Render(image, input->GetWidth(), input->GetHeight());

            // Update status bar with frame rate info
            char str[256];
            sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
                    input->GetHeight(), output->GetFrameRate());
            output->SetStatus(str);
            if (!output->IsStreaming()) break;  // Exit if user quits
        }

        // Render grayscale frame with histogram if output2 exists
        if (output2 != NULL) {
            output2->Render(d_output, input->GetWidth(), input->GetHeight());

            // Update status bar with frame rate info
            char str[256];
            sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
                    input->GetHeight(), output->GetFrameRate());
            output->SetStatus(str);
            if (!output->IsStreaming()) break;  // Exit if user quits
        }
    }
}
