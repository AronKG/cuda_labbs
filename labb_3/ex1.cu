#include <jetson-utils/videoSource.h>  // Include the header for video input source functionality
#include <jetson-utils/videoOutput.h>  // Include the header for video output display functionality


int main( int argc, char** argv )
{
    // Create input stream for video capture, using command-line arguments for configuration
    videoSource* input = videoSource::Create(argc, argv, ARG_POSITION(0));
    
    // Create output stream for video display, also using command-line arguments for configuration
    videoOutput* output = videoOutput::Create(argc, argv, ARG_POSITION(1));
    
    // If input stream couldn't be created, exit the program
    if ( !input )
        return 0;

    // Main loop for capturing and displaying frames
    while (true)
    {
        uchar4* image = NULL;  // Initialize a pointer to hold the captured image; uchar4 means each pixel has 4 channels (RGBA)
        int status = 0;  // Variable to track capture status (OK, TIMEOUT, EOS, ERROR)
        
        // Attempt to capture a frame with a 1000ms timeout; store the status
        if ( !input->Capture(&image, 1000, &status) )
        {
            // If capture timed out, continue the loop to try capturing again
            if (status == videoSource::TIMEOUT)
                continue;
            
            // If any other status (e.g., EOS), exit the loop to end the program
            break;
        }
        
        // Check if the output stream is initialized
        if ( output != NULL )
        {
            // Render the captured image on the output display with its dimensions
            output->Render(image, input->GetWidth(), input->GetHeight());
            
            // Update the status bar with the resolution and current frames per second (FPS)
            char str[256];
            sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
                    input->GetHeight(), output->GetFrameRate());
            output->SetStatus(str);
            
            // If the user has closed the output stream, exit the loop
            if (!output->IsStreaming())
                break;
        }
    }
}
