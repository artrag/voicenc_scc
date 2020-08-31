# voicenc_scc
Voice encoder for SCC chip. 
The speech is segmented in voiced and unvoiced segments. In voiced segments the pitch is extracted and used to compute an average waveform for that segment. 
Unvoiced segments are approximated by using the max peach of their spectrum. On standard SCC up to 4 samples can be played at the same time.
