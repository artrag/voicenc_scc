%function tt_voicenc_scc(input)
% test as tt_voicenc_scc("-50 -p")or as tt_voicenc_scc("-60 -p")

%input = " -p -50"; 
input = " -p -60"; 

close all

% Notes
% Konami values found in Nemesis 2 replayer.
% C_PER       equ   $6a*32      
% C1_PER      equ   $64*32
% D_PER       equ   $5e*32
% D1_PER      equ   $59*32
% E_PER       equ   $54*32
% F_PER       equ   $4f*32
% F1_PER      equ   $4a*32
% G_PER       equ   $46*32
% G1_PER      equ   $42*32
% A_PER       equ   $3f*32
% A1_PER      equ   $3b*32
% B_PER       equ   $38*32

% TRACK_ToneTable_PSG:    
%       dw C_PER/1  ,C1_PER/1  ,D_PER/1  ,D1_PER/1  ,E_PER/1  ,F_PER/1  ,F1_PER/1  ,G_PER/1  ,G1_PER/1  ,A_PER/1  ,A1_PER/1  ,B_PER/1
%       dw C_PER/2  ,C1_PER/2  ,D_PER/2  ,D1_PER/2  ,E_PER/2  ,F_PER/2  ,F1_PER/2  ,G_PER/2  ,G1_PER/2  ,A_PER/2  ,A1_PER/2  ,B_PER/2
%       dw C_PER/4  ,C1_PER/4  ,D_PER/4  ,D1_PER/4  ,E_PER/4  ,F_PER/4  ,F1_PER/4  ,G_PER/4  ,G1_PER/4  ,A_PER/4  ,A1_PER/4  ,B_PER/4
%       dw C_PER/8  ,C1_PER/8  ,D_PER/8  ,D1_PER/8  ,E_PER/8  ,F_PER/8  ,F1_PER/8  ,G_PER/8  ,G1_PER/8  ,A_PER/8  ,A1_PER/8  ,B_PER/8
%       dw C_PER/16 ,C1_PER/16 ,D_PER/16 ,D1_PER/16 ,E_PER/16 ,F_PER/16 ,F1_PER/16 ,G_PER/16 ,G1_PER/16 ,A_PER/16 ,A1_PER/16 ,B_PER/16
%       dw C_PER/32 ,C1_PER/32 ,D_PER/32 ,D1_PER/32 ,E_PER/32 ,F_PER/32 ,F1_PER/32 ,G_PER/32 ,G1_PER/32 ,A_PER/32 ,A1_PER/32 ,B_PER/32
%       dw C_PER/64 ,C1_PER/64 ,D_PER/64 ,D1_PER/64 ,E_PER/64 ,F_PER/64 ,F1_PER/64 ,G_PER/64 ,G1_PER/64 ,A_PER/64 ,A1_PER/64 ,B_PER/64
%       dw C_PER/128,C1_PER/128,D_PER/128,D1_PER/128,E_PER/128,F_PER/128,F1_PER/128,G_PER/128,G1_PER/128,A_PER/128,A1_PER/128,B_PER/128

T = hex2dec(['6a';'64';'5e';'59';'54';'4f';'4a';'46';'42';'3f';'3b';'38' ])'*32;
T = [T;T/2;T/4;T/8;T/16;T/32;T/64;T/128];
U = T(:);

if (contains(input,"-p",'IgnoreCase',true)) 
    playsample = true;
    fprintf('Playback on\n');
else
    playsample = false;
    fprintf('Playback off\n');
end

if (contains(input,"-60",'IgnoreCase',true)) 
    Tframe = 1/60;
    halfsec = 30;
    fprintf('Encoding for NTSC\n');
else
    Tframe = 1/50;
    halfsec = 25;
    fprintf('Encoding for PAL\n');
end

fprintf('\n');

path = 'wavs\';

names = dir([path '*.wav']);

if isempty(names)
    fprintf('I cannot find .wav files in %s \n',path);
    fprintf('Create %s and %s directories for input and output files\n',path,"data\");
    return
end

nfiles = size(names,1);


% voicebox('rapt_tframe',Tframe);
% voicebox('rapt_tlpw',Tframe/2);
% voicebox('rapt_tcorw',Tframe*0.75);
% v_voicebox('dy_spitch',0.4);

FFS = 22050;
Wl = 32;
    
fid_p = fopen('data\all_data_files_periods.asm','w');
fid_w = fopen('data\all_data_files_waves.asm','w');

SCCI = cell(1,nfiles);

Nbk = zeros(1,nfiles);

TPI = cell(1,nfiles);

%nfiles = 5;
for ii = 1:nfiles 
    
    name = [ path names(ii).name ];

    [Y,FS] = audioread(name);

    if size(Y,2)>1
        X = (Y(:,1)+Y(:,2));
    else
        X = (Y);
    end

    [P, Q] = rat(FFS/FS);
    X = resample(X,P,Q);
    FS = FFS;

    CX = v_zerotrim(round(256*X))/256;			% 8 bit version without ending zeros
    X = CX;
    
%    X = CX + randn(size(CX))*max(abs(CX))/64;
    
    Nntsc = fix(Tframe*FS);

    figure('Name',names(ii).name)
	[fx,tp,pv,~] = v_fxpefac(X,FS,Tframe,'G');
	
%    [fx,tp,pv,fv] = v_fxpefac(X,FS,Tframe);
%    q.tframe = Tframe;
%    [ffx,ttt] = v_fxrapt(X,FS,'g',q);
    
    Nblk = length(fx);
    Nbk(ii) = Nblk;
    
    YY = zeros((Nblk)*Nntsc,1);
    XX = zeros((Nblk)*Nntsc,1);

    SCC = zeros(Nblk,Wl);
    Ndft = 2^16;
	
    for i=1:Nblk
        ns  = round((tp(i)-Tframe/2)*FS);
        
        tti = (ns):(ns+Nntsc-1);            % choose one window

        s = [CX(tti); CX(tti); CX(tti);];   % same window 3 times to avoid edge effects
        
        XX(((i-1)*Nntsc+1):(i*Nntsc)) =  CX(tti);
        
        if (fx(i)>max([1/Tframe, 3579545/(32*2^12)]))
            
            if (pv(i)<=0.05) 						
                XF = abs(fft(s,Ndft));				% for unvoiced segments use the frequency peak
                [~,j] = max(XF(1:(Ndft/2)));
                fx(i) = max(1/Tframe,(j-1)/Ndft*FS/Wl);

                [P, Q] = rat(fx(i)*Wl/FS);
                ss = resample(s,P,Q);               % interpolate 3 windows

                sx = round(Tframe*fx(i)*Wl);
                dx = round(2*Tframe*fx(i)*Wl);
                np = fix((dx-sx)/Wl);
                ss = ss((sx+1):(sx+Wl));            % take W1 samples from the central window
            else			
                [P, Q] = rat(fx(i)*Wl/FS);          % for voiced segments use the pitch
                ss = resample(s,P,Q);               % interpolate 3 windows

                sx = round(Tframe*fx(i)*Wl);
                dx = round(2*Tframe*fx(i)*Wl);
                np = fix((dx-sx)/Wl);
                ss = mean(reshape(ss((sx+1):(sx+np*Wl)),Wl,np),2);     
            end

%             if (i>1)
%                 [~,kk] = min(abs(SCC(i-1,:)-ss'));
%             	ss = [ss(kk:32); ss(1:(kk-1))];
%             end

            SCC(i,:) = ss';
            y = resample(repmat(SCC(i,:),1,np+2),Q,P);

        else
            fx(i) = 0;
            SCC(i,:) = zeros(1,Wl);
            y = zeros(1,Nntsc);
        end
        
        YY(((i-1)*Nntsc+1):((i)*Nntsc)) =  y(1:Nntsc);
       
    end
    SCCI{ii} = SCC;

    figure('Name',names(ii).name)
    subplot(2,1,1)
    plot((1:size(XX,1))/FS,XX,'b.-',(1:size(YY,1))/FS,YY,'r.-');
    legend('Org','Rec');
    
    subplot(2,1,2)
    plot(tp,fx,'c');
    legend('pitch');
    
%    subplot(3,1,3)
%    plot(ffx)
%    legend('pitch apt');
    
    figure('Name',names(ii).name)
    spectrogram(XX,kaiser(Nntsc,8),fix(Nntsc/2),(0:1:FS/2),FS)
    title('Original');
    
    figure('Name',names(ii).name)
    spectrogram(YY,kaiser(Nntsc,8),fix(Nntsc/2),(0:1:FS/2),FS)
    title('Encoded');

    fprintf('file#%d  %s\n',ii,names(ii).name);
    
    if (playsample) 
        fprintf('Playing the original \n');
        obj = audioplayer(XX,FS);
        playblocking(obj);
        fprintf('Playing the SCC reproduction \n');
        obj = audioplayer(YY,FS);
        playblocking(obj);
    end
    
    [SNR,~] = snrseg(YY,XX,FS,'Vq',Tframe);
    fprintf('SNR = %f \n',SNR)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % write ASM output
    % MSX SCC
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    TP = uint16(3579545./(32*fx)-1);
    TP(TP>2^12-1) = 2^12-1;
    %TP = bitand(uint16(3579545./(32*fx)-1),2^12-1);
    TPI{ii} = TP;

    t = TPI{ii};
    s = SCCI{ii};
    
    p = mean(t(1:min([halfsec,size(t,1)])));              % average frequency from the first half second
    [~,f] = min(abs(p-U));
    Tbase = U(f);
    fprintf("Base SCC period: %d\n",Tbase);
    fprintf("Base frequency: %f\n\n",3579545/(Tbase+1)/32);
    
    data = round(s/(max(max(abs(s))))*127);
    i = find(data<0);
    data(i) = data(i)+256;
    data = uint8(data);

    fprintf(fid_p,'    CODE\nperiod%d:\n    dw ',ii);
    for j = 1:Nblk-1
        fprintf(fid_p,'0x%s,',dec2hex(TP(j),4));
    end
    fprintf(fid_p,'0x%s\n',dec2hex(TP(end),4));
    fprintf(fid_p,'    dw -1 ; frame terminator \n');
    
    fprintf(fid_w,'    CODE\n');
    fprintf(fid_w,'data%d:\n',ii);
    for i = 1:Nblk
        fprintf(fid_w,'    db ');
        for j = 1:31
            fprintf(fid_w,'0x%s,',dec2hex(data(i,j),2));
        end
        fprintf(fid_w,'0x%s\n',dec2hex(data(i,32),2));
     end
    
end

fclose(fid_p);
fclose(fid_w);

fid = fopen('data\all_data_files_index.asm','w');
for ii = 1:nfiles 
    fprintf(fid,'    ; %s\n',names(ii).name);
    fprintf(fid,'    db data%d / 02000h+1,:period%d\n',ii,ii);              % warning: data start at page 4!
    fprintf(fid,'    dw 06000h+(data%d & 01FFFh),period%d\n',ii,ii);
end
fprintf(fid,'nfiles: equ  %d \n\n',nfiles);
fclose(fid);

% !make.bat

fclose all;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TriloTracker export
% .SAM file
% 
%  [HEADER]
%   00-02 - "SAM"                           ; Header for identification 
%   03    - Version                         ; File layout version (for future changes)
%   04-05 - Base Tone                       ; Base tone (note) the sample is recorded. This is used for playback on different notes.
% [/HEADER]
% [FRAME] 0..(1 to max 481)
%   +00   - Period (tone)
%   +02   - Waveform (32 bytes)
% [/FRAME]
% [DELIMITER]
%   +00   - Action                          ; 0 = loop, other value = stop
%   +01   - 0xFF                            ; delimiter
%   +02-03 - Offset (negative)              ; (Optional) offset to the loop position in the data.
% [/DELIMITER]

for ii = 1:nfiles 

    fid = fopen(['data\TTsample' num2str(ii,'%.2d') '.sam'],'wb');

    t = TPI{ii};
    s = SCCI{ii};
    
    p = mean(t(1:min([halfsec,size(t,1)])));              % average frequency from the first half second
    [~,f] = min(abs(p-U));
%   Fbase  = 130.81;                                 % C3 = 130.81 Hz
%   Tbase  = uint16(3579545./(32*Fbase)-1);
    Tbase = U(f);
    header = uint8([ 'S' 'A' 'M' 0 bitand(Tbase,255) fix(Tbase/256)]);
    fwrite(fid,header,'uint8');

    

    data = round(s/(max(max(abs(s))))*127);
    i = find(data<0);
    data(i) = data(i)+256;
    data = uint8(data);

    for i = 1:Nbk(ii)
        fwrite(fid,t(i),'uint16');
        fwrite(fid,data(i,:),'uint8');
    end
    
    offset = 0;
    action = 255;       % STOP
    delimiter = uint8([ action 255 bitand(offset,255) fix(offset/256)]);
    fwrite(fid,delimiter,'uint8');
    
    fclose(fid);
end


