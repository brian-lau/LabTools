function fp_vec = getfp( spkt, n )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This function takes an array of spike time as input, and returns firing characteristics. 
%
%[EXAMPLE USAGE]
%clear;
%
%%Simulate spike train by drawing interspike intervals (ISIs) from the gamma distribution. 
%logkappa=2.0; loglambda=3.0;
%a=exp(logkappa); b=1/(exp(loglambda)*a);
%ISI=gamrnd(a,b,1,1000);
%spkt=horzcat(0.0,cumsum(ISI));
%
%%Compute firing characteristics
%%fp_vec = getfp(spkt, 100);
%
%[INPUT]
%spkt: an array containing spike time in unit of second.
%n: number of ISI for which firing characteristics are computed, and then averaged.
%   The default setting is n=20, and need not to be set by users.
%[OUTPUT]
%fp_vec: 1*4 array containing firing characteristics
%        fp_vec(1): Firing rate log lambda
%        fp_vec(2): Firign regularity log kappa
%        fp_vec(2): ISI correlation rho
%        fp_vec(3): Local variation of ISIs Lv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


switch nargin
    case 0
        error('Need spike times in the input.')
    case 1
        small_n=20;
    case 2
         small_n=n;
    otherwise
        error('Too many arguments in the input.')
end

ISI=diff(spkt);
ISI_num=max(size(ISI));
if small_n>ISI_num
        error('n need to be smaller than the total number of Inter-spike intervals.')
end


itt_max=floor(ISI_num/small_n);
fp_mat=zeros(itt_max,3);

    %compute loglambda, logkappa and rho for every small_n ISIs.
    for itt=1:itt_max
    ISI_itt=ISI((itt-1)*small_n+1:itt*small_n);
    
    %Estimate rate and regularity
    gpar = gamfit(ISI_itt);
    fp_mat(itt,2)=log(gpar(1));
    fp_mat(itt,1)=-log((gpar(1)*gpar(2)));

    %Estimate ISI correlation
    [ISI_sort, ISI_rank]=sort(ISI_itt);
    Rho_mat = corrcoef(ISI_rank(1:end-1),ISI_rank(2:end));
    fp_mat(itt,3)=Rho_mat(1,2);
    end
    fp_vec=mean(fp_mat);
    
    %compute lv for the entire spike train
    sum_lv=0.0;
    for i=1:ISI_num-1
        sum_lv=sum_lv+(ISI(i)-ISI(i+1))*(ISI(i)-ISI(i+1))/((ISI(i)+ISI(i+1))*(ISI(i)+ISI(i+1)));
    end
    lv=3.0*sum_lv/(ISI_num-1);
    fp_vec=horzcat(fp_vec, lv);
end

