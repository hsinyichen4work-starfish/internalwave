%% function [xf] = lowhighpass_butter(time,x,cutoff,N,pstring);
% Maarten Buijsman, USM, 2021-03-19
%
% pass filtering using buttter 
%
% INPUT:
%   vectors time [days] and x, 
%   cutoff, which indicates period of the cutoff frequency N the order (1..9) (5 is OK), 
%   pstring = 'low' or 'high' for low or highpass 
%
% OUTPUT: pass filtered vector xf

function [xf] = lowhighpass_butter(time,x,cutoff,N,pstring);

    cutoffreq    = 1./cutoff;               %% cycles per day
    DT           = time(2)-time(1); 
    sampfreq     = 1/DT;                    
    halfsampfreq = sampfreq*1/2;            %% Nyquist frequency
    Wn           = cutoffreq/halfsampfreq;  %% normalize by Nyquist fr, see examples in Matlab
    [bf,af]      = butter(N,Wn,pstring);
    xf           = filtfilt(bf,af,x);