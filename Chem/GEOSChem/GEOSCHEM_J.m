function J = GEOSCHEM_J(Met,Jmethod)
% function J = GEOSCHEM_J(Met,Jmethod)
% Calculates photolysis frequencies for GEOSCHEM.
% Mapping is based on the information found in the source files "ratj.d" and "jv_spec.dat".
%
% INPUTS:
% Met: structure containing required meteorological constraints. Required vars depend on Jmethod.
%       Met.SZA: solar zenith angle in degrees
%       Met.ALT: altitude, meters
%       Met.O3col: overhead ozone column, DU
%       Met.albedo: surface reflectance, 0-1 (unitless)
%       Met.T: temperature, T
%       Met.P: pressure, mbar
%       Met.LFlux: name of a text file containing an actinic flux spectrum
%
% Jmethod: numeric flag or string specifying how to calculate J-values. Default is 'MCM'.
%       0 or 'MCM':      use MCMv3.3.1 parameterization.
%                         Some reactions are not included in MCM. For these, "HYBRID" values are used.
%                         Required Met fields: SZA
%       1 or 'BOTTOMUP': bottom-up integration of cross sections/quantum yields.
%                         See J_BottomUp.m for more info.
%                         Required Met fields: LFlux, T, P
%       2 or 'HYBRID':   Interpolation of hybrid J-values from TUV solar spectra.
%                         See J_TUVhybrid.m for more info.
%                         Required Met fields: SZA, ALT, O3col, albedo
%
% OUTPUTS:
% J: structure of J-values
%
% 20151108 KRT
% 20160224 GMW Checked and cleaned.
% 20160304 GMW  Changed output from name/value pairs to structure, added Jmethod.

% INPUTS
struct2var(Met)

if nargin<2
    Jmethod = 'MCM';
elseif ischar(Jmethod)
    Jmethod = upper(Jmethod);
end

% J-Values
switch Jmethod
    case {0,'MCM'}
        Jmcm = MCMv331_J(Met,'MCM');
        
        % also need hybrid values for non-MCM species
        % override Met inputs to match hybrid and MCM J's (see Fig. 2 in description paper)
        ALT    = 500*ones(size(SZA)); %meters; 
        O3col  = 350*ones(size(SZA)); %DU
        albedo = 0.01*ones(size(SZA)); %unitless
        Jhyb   = J_Hybrid(SZA,ALT,O3col,albedo);
        
    case {1,'BOTTOMUP'}
        Jmcm = J_BottomUp(LFlux,T,P);
        Jhyb = Jmcm; %for name mapping
        
    case {2,'HYBRID'}
        Jmcm = J_Hybrid(SZA,ALT,O3col,albedo);
        Jhyb = Jmcm; %for name mapping
        
    otherwise
        error(['MCMv331_J: invalid Jmethod "' Jmethod ...
            '". Valid options are "MCM" (0), "BOTTOMUP" (1), "HYBRID" (2).'])
end

% RENAME
J=struct;
J.JO1D        = Jmcm.J1;
J.JH2O2       = Jmcm.J3;
J.JNO2        = Jmcm.J4;
J.JNO3_NO     = Jmcm.J5;
J.JNO3_NO2    = Jmcm.J6;
J.JHONO       = Jmcm.J7;
J.JHNO3       = Jmcm.J8;
J.JHCHO_HO2   = Jmcm.J11;
J.JHCHO_H2    = Jmcm.J12;
J.JALD2a      = Jmcm.J13; % MCM only considers radical channel
J.JRCHO       = Jmcm.J14;
J.JMACR       = Jmcm.J18 + Jmcm.J19;
J.JHPALD      = Jmcm.J20;
J.JMVK        = Jmcm.J23 + Jmcm.J24; %put 60/20/20 branching in reaction file
J.JACETa      = Jmcm.J21; %MCM only considers this channel
J.JMEK        = Jmcm.J22;
J.JGLYXb      = Jmcm.J31 + Jmcm.J32; %based on products, this should include both channels
J.JGLYXa      = Jmcm.J33;
J.JMGLY       = Jmcm.J34;
J.JMP         = Jmcm.J41;
J.JR4N2       = Jmcm.J51;
J.JONIT1      = Jmcm.J53;

% NOTE: for these carbonyl nitrates, GEOS-CHEM/FAST-JX uses cross sections calculated
% following Muller et al., ACP (2014). For now we have just assigned these to the scaling
% factors given in MCMv3.3.1.
J.JPROPNN     = Jmcm.J56;
J.JETHLN      = Jmcm.J56*4.3;
J.JMVKN       = Jmcm.J56*1.6;
J.JMACRN      = Jmcm.J56*10;

% NO DIRECT MCM ANALOGUES
J.JALD2b         = Jhyb.Jn5; % ch3cho; MCM only considers radical channel; FAST JX has QY=0
J.JACETb         = Jhyb.Jn8; %acetone
J.JHAC           = Jhyb.Jn10;
J.JGLYC          = Jhyb.Jn9;
J.JHNO4          = Jhyb.Jn21 + Jhyb.Jn22;
J.JN2O5_NO2      = Jhyb.Jn19; % N2O5 --> NO3 + NO2
J.JN2O5_NO       = Jhyb.Jn20; % N2O5 -> NO3+NO+O, turned off in GC
J.JPAN           = Jhyb.Jn14 + Jhyb.Jn15; %70/30 quantum yields set in chem file
J.JMPN           = Jhyb.Jn16 + Jhyb.Jn17; %95/5 quantum yields set in chem file
J.JBr2           = Jhyb.Jn24;
J.JBrO           = Jhyb.Jn25; 
J.JHOBr          = Jhyb.Jn26;
J.JBrNO2         = Jhyb.Jn27;
J.JBrNO3_Br      = Jhyb.Jn28;
J.JBrNO3_BrO     = Jhyb.Jn29;
J.JCHBr3         = Jhyb.Jn30;


