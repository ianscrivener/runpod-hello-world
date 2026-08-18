import subprocess

import runpod

def handler(job):
    """
    This is a simple handler that takes a name as input and returns a greeting.
    The job parameter contains the input data in job["input"]
    """
    job_input = job["input"]

    # Get the name from the input, default to "World" if not provided
    name = job_input.get("name", "World") #

    result = subprocess.run(
        ["nvidia-smi"], capture_output=True, text=True
    )
    nvidia_smi_output = result.stdout if result.returncode == 0 else result.stderr

    # Return a greeting message
    return (
        f"Hello, {name}! Welcome to Runpod Serverless! How are you doing?\n\n"
        f"{nvidia_smi_output}"
    )

# Start the serverless function
runpod.serverless.start({"handler": handler})
