function Burst = legendy_new3(ISI,fac,sampling_rate,min_length_of_burst,local_length,surprise_cutoff)
% Function Burst = legendy_new3(ISI,fac,sampling_rate,min_length_of_burst,local_length,surprise_cutoff)
% carries out the burst detection algorithm by Legendy and Salcman (J. Neurophysiology 53:926) on 
% the input ISI data stream.  The sampling rate defaults to 1000 Hz, but can be altered by giving
% the sampling_rate as an input parameter.  As the initial criterion for burst detection, spikes 
% have to occur at a frequency which is higher than the baseline frequency by a factor fac.  The
% user can modify the minimal length of a prospective burst (min_length_of_burst), and the surprise
% cutoff value.  In the original paper, this value was set to 10 to detect significant spikes.
% The burst discharge is compared to a segment of data immediately preceding the burst.  A local_length
% value of 0 indicates that the entire data stream should be used to yield the firing rate (can be used
% in case of homogeneous firing of units).  Other values indicate a local time interval that should be
% used (for instance, a value of 1 would mean that each spike/burst is compared to 1 second of data
% prior to the index spike).
%
% The function makes use of a subroutine called surprise_new3.  The function returns 100 for
% a very high surprise value and 0 for a very low one.  This means that the output of this rou-
% tine is not accurate for such very high or very low surprise values (although bursts are correctly
% detected).  
%
% The function produces a structure (Burst) which contains fields describing the bursts, including the 
% onset and lengths of bursts (described as indices of the input ISI stream) the highest rate within 
% the burst, the average discharge rate in the burst, the pre-burst baseline rate, as well as the 
% surprise values for individual bursts.  In field 1 of the structure, summary parameters are defined, 
% including, num_bursts (the total number of bursts detected), mean_spikes_per_burst, total_spikes_in_bursts, 
% mean_intra_burst_frequency, proportion_time_in_bursts, and proportion_spikes_in_bursts.
%
% Defaults: surprise_cutoff = 10, local_length = 0, min_length_of_burst = 2, sampling_rate = 1000, fac = 1.5
%
% Usage: Bursts = legendy_new3(A,2,10000,4,1000,10);
%
% This call would detect bursts in the input ISI stream A, sampled at 10000 Hz; ISIs within such bursts
% would have to fire at at least twice the local firing rate, and would have to be at least 4 spikes 
% in length.  The comparison firing rates would be computed using 1000 spikes preceding the prospective 
% bursts.  Bursts would have to have a surprise value of at least 10.
%
% Written 9/21-23/2001, 7/24/2003, 11/27/2003, 7/31/2005, 1/4/2007 by Thomas Wichmann.

if nargin < 6, surprise_cutoff = 10;end
if nargin < 5 | isempty(local_length), local_length = 0;end
if nargin < 4 | isempty(min_length_of_burst),min_length_of_burst = 2;end
if nargin < 3 | isempty(sampling_rate),sampling_rate = 1000;end
if nargin < 2 | isempty(fac),fac = 1.5;end

Burst = struct('begin',[],'num_spikes',[],'surprise',[],'rate',[],'max_rate',[],'baseline_rate',[],'num_bursts',[],'mean_spikes_per_burst',[],'median_spikes_per_burst',[],'total_spikes_in_bursts',[],'mean_intra_burst_frequency',[],'median_intra_burst_frequency',[],'proportion_time_in_bursts',[],'proportion_spikes_in_bursts',[]);

burst_num = 0;
CA = cumsum(ISI);

if local_length == 0,
    mean_FR = length(ISI)/(sum(ISI)/sampling_rate);
    fr_thr = sampling_rate/(fac*mean_FR);   % calculation of frequency threshold
    beg_idx = 0;
else
    beg_idx = find(CA < local_length*sampling_rate,1,'LAST');     % finds last index within the 'local length' - incremented by one, this will result in the first index that can be evaluate.
end
n = beg_idx;

% ***** Main loop ****

while n < length(ISI) - min_length_of_burst

    n = n+1;                                                                    % n is a running parameter that points to ISIs
    
    if local_length > 0,
        I = ISI(find(CA > CA(n)-local_length*sampling_rate,1,'FIRST'):n-1);     % find the ISI data segment I that is fully contained within the local_length
        mean_FR = length(I)/(sum(I)/sampling_rate);
        fr_thr = sampling_rate/(fac*mean_FR);                                   % calculation of frequency threshold
    end
    
    
    % ****** 1. selection step - find runs of short ISIs *******************
    if (ISI(n) < fr_thr) % finding areas of the spike train which fulfill the length_of_burst criterion

        q = 0;           % running parameter that points to the number of spikes to be added
        inc_flag = 0;
        while (n+q <= length(ISI)) & (ISI(n+q) < fr_thr)
            q = q+1;
            inc_flag = 1;
        end
        if inc_flag,
            q = q-1;                                                                % reverse the last addition of q that led to the end of the while routine;
        end
        
        % at this point, the provisional burst starts at n and ends at n+q;
        % it has q+1 spikes in it
    
        
    % ******* 2. selection step - adjust length of burst to maximize surprise value ***************
        if q+1 >= min_length_of_burst,    
            m = min_length_of_burst;                                            % running parameter of the number of spikes to be added to n
            inc_flag = 0;
            while ((n+m <= length(ISI)) & ...
                    (ISI(n+m) < fr_thr) & ...
                    (surprise_new3(mean_FR,ISI(n:n+m),sampling_rate) >= surprise_new3(mean_FR,ISI(n:n+m-1),sampling_rate))),   % 2. burst criterion - surprise values are increasing when spikes are added 
                m = m+1;
                inc_flag = 1;
            end
            if inc_flag,
                m = m-1;                            % reverse the last addition steps that resulted in the termination of the while loop
            end
           
            % at this point, the beginning of the burst is provisionally settled to be n, the end n+m
            % the burst has m+1 spikes in it.
            
    % ******* 3. selection step - test whether adding up to 10 more ISIs will enhance surprise value **********************
            if n+m+10 <= length(ISI) % mmax is set to 10 unless one couldn't add 10 to n before reaching the end of FR
                mmax = 10;
            else
                mmax = length(ISI)-(n+m);
            end
        
            ind_long_ISI = find(ISI(n+m+1:n+m+mmax) > fr_thr,1,'FIRST');        % looking for 'slow spikes' within the next 10 spikes after the current burst end
            if ~isempty(ind_long_ISI)                                           % pmax is set to be the index of the slow spike
                pmax = ind_long_ISI-1;
            else
                pmax = mmax;
            end
            
            S = zeros(pmax+1,1);                                                % formation of an array that will contain surprise values.  The first one is that of the burst defined by the ISIs between n and n+m.  Additional entries into S are surprise values that would result from adding up to pmax additional spikes (S2 will be the surprise values for ISI(n:n+m+1), S3 the one for ISI(n:n+m+2) etc.)
            S(1) = surprise_new3(mean_FR,ISI(n:n+m),sampling_rate);                                        
            for p = 1:pmax                                  % forms array of surprise values for this burst, starting from the end of the burst to pmax values later
                S(p+1) = surprise_new3(mean_FR,ISI(n:n+m+p),sampling_rate);
            end
            [max_S,ind_max_S] = max(S);            

            if n+m < length(ISI)
                m = m+ind_max_S-1;                          % this will set the m-value to the previous m, if the first entry into the S array is the highest (i.e., if adding additional ISIs didn't increase the surprise value), or, it will correct m to the highest value
            else
                m = length(ISI)-n;
            end
        
            % at this point, the end of the index of the end of the burst
            % is settled to be n+m
            
            
        % ******** 4. selection step - test whether adjusting the front end of the burst enhances the surprise value ******************
            if n > 1,
                o = 1; 
                inc_flag = 0;
                while((m-o > min_length_of_burst) & ...
                        (surprise_new3(mean_FR,ISI(n+o:n+m),sampling_rate) >= surprise_new3(mean_FR,ISI(n+o-1:n+m),sampling_rate))),
                    o = o+1;
                    inc_flag = 1;
                end
                
                if inc_flag,
                    o = o - 1;          % reducing o by one to correct for the addition that resulted in the end of the while loop
                    n = n+o;            % adjust the beginning of the burst
                    m = m-o;            % adjust the length of the burst
                end
            end
        
            % at this point, the beginning of the burst is settled to be n, and the length is m+1 ***
            
            if (m+1 >= min_length_of_burst) & (surprise_new3(mean_FR,ISI(n:n+m),sampling_rate) > surprise_cutoff), 
                burst_num = burst_num + 1;
                Burst(burst_num).begin = n;
                Burst(burst_num).num_spikes = m+1;
                Burst(burst_num).surprise = surprise_new3(mean_FR,ISI(n:n+m),sampling_rate);
                Burst(burst_num).rate = length(ISI(n:n+m))/(sum(ISI(n:n+m))/sampling_rate);
                Burst(burst_num).max_rate = sampling_rate/min(ISI(n:n+m));
                Burst(burst_num).baseline_rate = mean_FR;
            end        
            
            n = n+m+1;                                                      % adjust ISI pointer to the ISI following the burst
            
        end
    end
end


% ****** Store burst parameters in the output array
if ~isempty(Burst(1).begin),
    C = zeros(length(Burst),1);
    Burst(1).num_bursts = length(Burst);
    for n = 1:length(Burst),
        C(n) = Burst(n).num_spikes;
    end;
    Burst(1).mean_spikes_per_burst = mean(C);
    Burst(1).median_spikes_per_burst = median(C);
    Burst(1).total_spikes_in_bursts = sum(C);
    
    for n = 1:length(Burst),
        C(n) = Burst(n).rate;
    end;
    Burst(1).mean_intra_burst_frequency = mean(C);
    Burst(1).median_intra_brst_frequency = median(C);
    Burst(1).proportion_time_in_bursts = (Burst(1).total_spikes_in_bursts/Burst(1).mean_intra_burst_frequency)/(sum(ISI(beg_idx+1:length(ISI)))/sampling_rate);
    Burst(1).proportion_spikes_in_bursts = Burst(1).total_spikes_in_bursts/length(ISI(beg_idx+1:length(ISI)));
else 
    Burst(1).num_bursts = 0;
    Burst(1).mean_spikes_per_burst = 0;
    Burst(1).median_spikes_per_burst = 0;
    Burst(1).total_spikes_in_bursts = 0;
    Burst(1).mean_intra_burst_frequency = 0;
    Burst(1).median_intra_burst_frequency = 0;
    Burst(1).proportion_time_in_bursts = 0;
    Burst(1).proportion_spikes_in_bursts = 0;
end

% ******* Exit ***********

%**********************************************************************
function [burst,deceleration] = surprise_new3(r,data,sampling_rate)
% calculates surprise index.  Parameters are ...
% r = comparison firing rate (spikes per second)
% data = ISI data to be included in the burst
% sampling_rate = sampling rate of ISI measurements

T = sum(data)/sampling_rate;
num_spikes = length(data);

p = poisscdf(num_spikes,r*T);

switch p
    case 0                                      % for very small p, a value of 10exp-100 is assumed
        burst = 0;
        if nargout > 1,deceleration = 100;end
    case 1                                      % for very high p, a value of 1-10exp-100 is assumed    
        burst = 100;    
        if nargout > 1,deceleration = 0;end
    otherwise
        burst = -log(1-p);
        if nargout > 1,deceleration = -log10(p);end
end


%************************************************************************