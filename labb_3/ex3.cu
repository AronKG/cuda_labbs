co#include <jetson-utils/videoSource.h>
#include <jetson-utils/videoOutput.h>

__global__ void rgb2grayKernel(uchar4* image, uchar4* output, int width, int height)
{ 
    
    long int size = width*height; 
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < size; i += stride) {
    
        unsigned char gray = (0.299*image[i].x) + (0.587*image[i].y) + (0.114*image[i].z); 
        output[i].x  = gray; 
        output[i].y = gray; 
        output[i].z = gray; 
    }

}


int main( int argc, char** argv )
{
    // create input/output streams
    videoSource* input = videoSource::Create(argc, argv, ARG_POSITION(0));
    videoOutput* output = videoOutput::Create(argc, argv, ARG_POSITION(1));
    videoOutput* output2 = videoOutput::Create(argc, argv, ARG_POSITION(1));

    if ( !input )
    return 0;

    uchar4* d_output;
        size_t imageSize = input->GetWidth() * input->GetHeight() * sizeof(uchar4);

    cudaMalloc((void**)&d_output, imageSize);

// capture/display loop
    while (true)
    {
        uchar4* image = NULL; // can be uchar3, uchar4, float3, float4
        int status = 0; // see videoSource::Status (OK, TIMEOUT, EOS,ERROR)
        if ( !input->Capture(&image, 1000, &status) ) // 1000ms timeout (default)
        {
            if (status == videoSource::TIMEOUT)
            continue;
            break; // EOS
        }
        rgb2grayKernel<<<16, 1024>>>(image, d_output, input->GetWidth(), input->GetHeight());

        if ( output != NULL )
        {
            output->Render(image, input->GetWidth(), input->GetHeight());


            // Update status bar
            char str[256];
            sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
            input->GetHeight(), output->GetFrameRate());
            output->SetStatus(str);
            if (!output->IsStreaming()) // check if the user quit
            break;
      }

      if ( output2 != NULL )
      {

          output2->Render(d_output, input->GetWidth(), input->GetHeight());

          // Update status bar
          char str[256];
          sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
          input->GetHeight(), output->GetFrameRate());
          output->SetStatus(str);
          if (!output->IsStreaming()) // check if the user quit
          break;
    }
    }

}