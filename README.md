# voicenc_scc
Voice encoder for SCC chip in Matlab. 
The speech is segmented in voiced and unvoiced segments. In voiced segments the pitch is extracted and used to compute an average waveform for that segment. 
Unvoiced segments are approximated by using the max peach of their spectrum. On standard SCC up to 4 samples can be played at the same time.


To run the encoder you need Matlab 2017 and the toolbox sap-voicebox

Download the full directory sap-voicebox and install the toolbox  in your Matlab path 
Download the full directory voicenc_scc

Replace the audio files in subdir \wav with your own

RUN matlab
Make sure that "sap-voicebox-master\voicebox" is in your matlab path 
Move to voicenc_scc\

Run voicenc_scc.m
All coded data will be stored in \data and the sccLOFI_1c.rom will be updated

Run the rom in an emulator (Mapper ASCII) with an SCC in the second slot
Type  ? USR(n) to run effect n

Up to 4 samples can be played at the same time.
