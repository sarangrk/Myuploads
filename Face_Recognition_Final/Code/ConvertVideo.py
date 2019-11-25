import skvideo.io
import numpy as np

def convert(input_path_new,output_path_new):
    videogen = skvideo.io.vread(input_path_new)
    writer = skvideo.io.FFmpegWriter(output_path_new)
    for frame in videogen:
        writer.writeFrame(frame)
    writer.close()
