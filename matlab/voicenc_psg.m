%function voicenc_psg(input);

close all

input = [];

path = 'wavs\';

names = dir([path '_*.*']);

nfiles = size(names,1);

Tntsc = 1/60;
% voicebox('rapt_tframe',Tntsc);
% voicebox('rapt_tlpw',Tntsc/2);
% voicebox('rapt_tcorw',Tntsc*0.75);
% v_voicebox('dy_spitch',0.4);

FFS = 32000;

% fid_p = fopen('data\all_data_files_periods.asm','w');
% fid_w = fopen('data\all_data_files_waves.asm','w');

SCCI = [];

%nfiles = 1;
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
    
%     c=find(x>1/128,1,'first');
%     r=find(x>1/128,1,'last');
%     X=x(c:r);
    X = v_zerotrim(round(256*X))/256;

    FS = FFS;
    
    Nntsc = fix(Tntsc*FS);

%    figure;[fx,tt,pv,fv] = v_fxpefac(X,FS,Tntsc,'G');
    [fx,tt,pv,fv] = v_fxpefac(X,FS,Tntsc);
    [ffx,ttt]=v_fxrapt(X,FS);
    
    Nblk = length(fx);
  
    YY = zeros((Nblk)*Nntsc,1);
    XX = zeros((Nblk)*Nntsc,1);

    B = 64;
    SCC = zeros(Nblk,B);
    
    for i=1:Nblk

        tti = (round((tt(i)-Tntsc/2)*FS)):(round((tt(i)-Tntsc/2)*FS)+Nntsc-1);
        s = X(tti);
        
        if (fx(i)==0)
            fx(i) = 1;
        end
        
        [P, Q] = rat(fx(i)*B/FS);
        ss = resample(s,P,Q);
        np = fix(length(ss)/B);
        SCC(i,:) = mean(reshape(ss(1:(np*B)),B,np),2);
        FSCC = abs(fft(SCC(i,:)));
        F = [0:(B-1)];
        [PKS,LOCS] = findpeaks(FSCC(1:B/2),F(1:B/2),'SortStr','descend','NPeaks',3);
        [LOCS fx(i)]
        
        y = resample(repmat(SCC(i,:),1,np+1),Q,P);
        
        YY(((i-1)*Nntsc+1):((i)*Nntsc)) =  y(1:Nntsc);
        XX(((i-1)*Nntsc+1):((i)*Nntsc)) =  s;
       
    end
    SCCI = [ SCCI; SCC];

    figure('Name',names(ii).name)
    subplot(3,1,1)
    plot((1:size(XX,1))/FS,XX,'b',(1:size(YY,1))/FS,YY,'r');
    legend('Org','Rec');
    subplot(3,1,2)
    plot(tt,fx,'c');
    legend('pitch');
    subplot(3,1,3)
    plot(ffx)
    legend('pitch apt');
    
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

    TP = bitand(uint16(3579545./(32*fx)-1),2^15-1);
    data = round(SCC/(max(max(abs(SCC))))*127);
    i = find(data<0);
    data(i) = data(i)+256;
    data = uint8(data);

%     fprintf(fid_p,'    CODE\nperiod%d:\n    dw ',ii);
%     for j = 1:Nblk-1
%         fprintf(fid_p,'0x%s,',dec2hex(TP(j),4));
%     end
%     fprintf(fid_p,'0x%s\n',dec2hex(TP(end),4));
%     fprintf(fid_p,'    dw -1 ; frame terminator \n');
%     
%     fprintf(fid_w,'    CODE\n');
%     fprintf(fid_w,'data%d:\n',ii);
%     for i = 1:Nblk
%         fprintf(fid_w,'    db ');
%         for j = 1:31
%             fprintf(fid_w,'0x%s,',dec2hex(data(i,j),2));
%         end
%         fprintf(fid_w,'0x%s\n',dec2hex(data(i,32),2));
%      end
    
end

% fclose(fid_p);
% fclose(fid_w);
% 
% fid = fopen('data\all_data_files_index.asm','w');
% for ii = 1:nfiles 
%     fprintf(fid,'    ; %s\n',names(ii).name);
%     fprintf(fid,'    db data%d / 02000h+1,:period%d\n',ii,ii);              % waring: data start at page 4!
%     fprintf(fid,'    dw 06000h+(data%d & 01FFFh),period%d\n',ii,ii);
% end
% fprintf(fid,'nfiles: equ  %d \n\n',nfiles);
% fclose(fid);


!make.bat

fclose all;

%% Waveform Compression
%
% [IDX, C] = kmeans(SCCI, 256);
% 
% Cdata = round(C/(max(max(abs(C))))*127);
% i = find(Cdata<0);
% Cdata(i) = Cdata(i)+256;
% Cdata = uint8(Cdata);
