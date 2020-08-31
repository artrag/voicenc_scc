%function voicenc(input);

close all

input = [];

path = 'wavs\';

names = dir([path '*.wav']);

nfiles = size(names,1);

Tntsc = 1/60;
% voicebox('rapt_tframe',Tntsc);
% voicebox('rapt_tlpw',Tntsc/2);
% voicebox('rapt_tcorw',Tntsc*0.75);
% v_voicebox('dy_spitch',0.4);

FFS = 22050;
Wl = 32;
    
fid_p = fopen('data\all_data_files_periods.asm','w');
fid_w = fopen('data\all_data_files_waves.asm','w');

SCCI = [];
TPI = [];

Nbk = zeros(1,nfiles);

%nfiles = 5;
for ii = 1:nfiles 
    
    fprintf('file#%d  %s\n',ii-1,names(ii).name);
    
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
    
    Nntsc = fix(Tntsc*FS);

    figure;
	[fx,tp,pv,fv] = v_fxpefac(X,FS,Tntsc,'G');
	
%    [fx,tp,pv,fv] = v_fxpefac(X,FS,Tntsc);
%    [ffx,ttt] = v_fxrapt(X,FS);
    
    Nblk = length(fx);
    Nbk(ii) = Nblk;
    
    YY = zeros((Nblk)*Nntsc,1);
    XX = zeros((Nblk)*Nntsc,1);

    SCC = zeros(Nblk,Wl);
    Ndft = 2^16;
	
    for i=1:Nblk
        ns  = round((tp(i)-Tntsc/2)*FS);
        
        tti = (ns):(ns+Nntsc-1);            % choose one window

        s = [CX(tti); CX(tti); CX(tti);];   % same window 3 times to avoid edge effects
        
        XX(((i-1)*Nntsc+1):(i*Nntsc)) =  CX(tti);
        
        if (fx(i)>max([1/Tntsc, 3579545/(32*2^12)]))
            
            if (pv(i)<=0.05) 						
                XF = abs(fft(s,Ndft));				% for unvoiced segments use the frequency peak
                [~,j] = max(XF(1:(Ndft/2)));
                fx(i) = max(1/Tntsc,(j-1)/Ndft*FS/Wl);

                [P, Q] = rat(fx(i)*Wl/FS);
                ss = resample(s,P,Q);               % interpolate 3 windows

                sx = round(Tntsc*fx(i)*Wl);
                dx = round(2*Tntsc*fx(i)*Wl);
                np = fix((dx-sx)/Wl);
                ss = ss((sx+1):(sx+Wl));     
            else									% for voiced segments use the pitch
                [P, Q] = rat(fx(i)*Wl/FS);
                ss = resample(s,P,Q);               % interpolate 3 windows

                sx = round(Tntsc*fx(i)*Wl);
                dx = round(2*Tntsc*fx(i)*Wl);
                np = fix((dx-sx)/Wl);
                ss = mean(reshape(ss((sx+1):(sx+np*Wl)),Wl,np),2);     
            end

%             kk = 1+fix(rem(Tntsc,1/fx(i))*fx(i)*Wl);
%             [~,kk] = min(abs(SCC(i-1,kk)-ss));
%            SCC(i,:) = [ss(kk:end); ss(1:(kk-1))]';

            SCC(i,:) = ss';
            y = resample(repmat(SCC(i,:),1,np+2),Q,P);

        else
            fx(i) = 0;
            SCC(i,:) = zeros(1,Wl);
            y = zeros(1,Nntsc);
        end
        
        YY(((i-1)*Nntsc+1):((i)*Nntsc)) =  y(1:Nntsc);
       
    end
    SCCI = [ SCCI; SCC];

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
    
    figure; 
    spectrogram(XX,kaiser(Nntsc,8),fix(Nntsc/2),(0:1:FS/2),FS)
    title('Original');
    
    figure; 
    spectrogram(YY,kaiser(Nntsc,8),fix(Nntsc/2),(0:1:FS/2),FS)
    title('Encoded');

    
%     obj = audioplayer(XX,FS);
%     playblocking(obj);
%     obj = audioplayer(YY,FS);
%     playblocking(obj);
 
     [SNR,glo] = snrseg(YY,XX,FS,'Vq',Tntsc);
     disp(SNR)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % write output
    % MSX SCC
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    TP = uint16(3579545./(32*fx)-1);
    TP(TP>2^12-1) = 2^12-1;
    %TP = bitand(uint16(3579545./(32*fx)-1),2^12-1);
    TPI = [TPI; TP];
    
    data = round(SCC/(max(max(abs(SCC))))*127);
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


!make.bat

fclose all;


%% Waveform Compression
%
codebook = 2^12;
disp('codebook:'); disp(codebook);
nc = min(size(SCCI,1),codebook);
[IDX, C] = kmeans(SCCI, nc);

Cdata = round(C/(max(max(abs(C))))*127);
i = find(Cdata<0);
Cdata(i) = Cdata(i)+256;
Cdata = uint8(Cdata);

fid_p = fopen('data\compressed_data.asm','w');
fprintf(fid_p,'    ; dw period,wavenumber \n\n');
for ii = 1:nfiles
    fprintf(fid_p,'    ; %s\n',names(ii).name);
    
    t = sum(Nbk(1:ii-1));
    ID = IDX(t+1:t+Nbk(ii));
    TP = TPI(t+1:t+Nbk(ii));
    
    fprintf(fid_p,'    CODE\n');
    fprintf(fid_p,'sample%d:\n',ii);
    for j = 1:Nbk(ii)-1
        fprintf(fid_p,'    dw 0x%s,',dec2hex(TP(j),4));
        fprintf(fid_p,'0x%s\n',dec2hex(ID(j)-1,4));
    end
    fprintf(fid_p,'    dw 0x%s,',dec2hex(2^15+TP(end),4));
    fprintf(fid_p,'0x%s\n',dec2hex(ID(end),4));
%     fprintf(fid_p,'    dw 0x%s,',dec2hex(2^15,4));
%     fprintf(fid_p,'0x%s\n',dec2hex(2^15,4));
end
fclose(fid_p);

fid_w = fopen('data\compressed_data_waves.asm','w');
for i = 1:size(Cdata,1)
    fprintf(fid_w,'    db ');
    for j = 1:31
        fprintf(fid_w,'0x%s,',dec2hex(Cdata(i,j),2));
    end
    fprintf(fid_w,'0x%s\n',dec2hex(Cdata(i,32),2));
end
fclose(fid_w);


fid = fopen('data\compressed_files_index.asm','w');
for ii = 1:nfiles
    fprintf(fid,'    ; %s\n',names(ii).name);
    fprintf(fid,'    db ');
    fprintf(fid,':sample%d+sample%d/0x2000-3\n',ii,ii);
    fprintf(fid,'    dw ');    
    fprintf(fid,'0x6000+(sample%d & 0x1FFF)\n',ii);
end
fprintf(fid,'nfiles: equ  %d \n\n',nfiles);
fclose(fid);

!make_VQ.bat
