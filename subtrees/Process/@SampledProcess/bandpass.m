function [self,b] = bandpass(self,corner,order)
%b = firls(MUA_FILT_ORDER,[0 450/nyquist 500/nyquist 2500/nyquist 2550/nyquist 1],[0 0 1 1 0 0]);
