# voicenc_scc
Voice encoder for SCC chip. The speech is segmented in voiced and unvoiced segment. The pitch is extracted in voiced segments and used to compute a a mean waveform for that segment. Unvoiced segments are approximated using the max of their spectrum. On standard SCC up to 4 saplesa can be played at the same time.
