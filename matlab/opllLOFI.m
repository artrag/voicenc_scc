
% volumes bit 3:24 dB bit 2:12 dB bit 1:6 dB bit 0:3 dB
% frequency 
%
%The 8 bits of $1X with a 9th bit from bit 0 of $2X create a 9-bit frequency value (freq). 
% This is combined with a 3-bit octave value from $2X (octave) to define the output frequency (F):
%     49716 Hz * freq
%F = -----------------
%     2^(19 - octave)

% find freq (9 bits) and octave (7 bits)

%http://wiki.nesdev.com/w/index.php/VRC7_audio
%http://www.smspower.org/maxim/Documents/YM2413ApplicationManual

