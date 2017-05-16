%input data
clear all;
%% system data
sysFile='data\sys.xlsx';
A=xlsread(sysFile,'B1:B1');               %% number of areas
T=xlsread(sysFile,'B2:B2');               %% time horizons
TD=0;                                     %% number of days
%% area data
areaFile{1}='data\area_1.xlsx';
areaFile{2}='data\area_2.xlsx';
Nunit = [53,19];            %% number of units
Ntie  = [1,1];            %% number of tie lines
%%------------------------ initialization ---------------------------------
Pmax=cell(1,A);           %% unit maximum output
Pmin=cell(1,A);           %% unit minimum output
Rampup=cell(1,A);         %% unit ramping up rates
Rampdown=cell(1,A);       %% unit ramping down rates
Minup=cell(1,A);          %% unit minimun up time
Mindown=cell(1,A);        %% unit minimum dowm time
Onoff_t0=cell(1,A);       %% initial status at t=0
Pthermal_t0=cell(1,A);    %% initial output at t=0
On_t0=cell(1,A);          %% length of time unit g has to be on at the beginning
Off_t0=cell(1,A);         %% length of time unit g has to be off at the beginning
Demand=zeros(T,A);        %% demand
Windmax= zeros(T,A);      %% theory output of wind power
PVmax  = zeros(T,A);      %% theory output of PV
Tieline=cell(1,A);        %% tie lines
Ftie0=cell(1,A);          %% fixed power flow
Etie =cell(1,A);          %% exchage energy each day
TDstart=ones(1,TD+1);
ReserveUp=ones(T,A);      %% up reserve
ReserveDn=ones(T,A);      %% down reserve
%%------------------------------ read data---------------------------------
for a=1:A
    %%------------------------- unit data ---------------------------------
    Pmax{a}        = xlsread(areaFile{a},1,['B2:B' num2str(Nunit(a)+1)])';
    Pmin{a}        = xlsread(areaFile{a},1,['C2:C' num2str(Nunit(a)+1)])';
    Rampup{a}      = xlsread(areaFile{a},1,['D2:D' num2str(Nunit(a)+1)])';
    Rampdown{a}    = xlsread(areaFile{a},1,['E2:E' num2str(Nunit(a)+1)])';
    Minup{a}       = xlsread(areaFile{a},1,['F2:F' num2str(Nunit(a)+1)])';
    Mindown{a}     = xlsread(areaFile{a},1,['G2:G' num2str(Nunit(a)+1)])';
    Onoff_t0{a}    = xlsread(areaFile{a},1,['H2:H' num2str(Nunit(a)+1)])';
    Pthermal_t0{a} = xlsread(areaFile{a},1,['I2:I' num2str(Nunit(a)+1)])';
    On_t0{a}       = xlsread(areaFile{a},1,['J2:J' num2str(Nunit(a)+1)])';
    Off_t0{a}      = xlsread(areaFile{a},1,['K2:K' num2str(Nunit(a)+1)])';
    %%------------------------- Demand data -------------------------------------
    Demand(:,a)    = xlsread(areaFile{a},2,['B2:B' num2str(T+1)]);     %% demand of each area
    %%------------------------- Resever data -------------------------------------
    %ReserveUp=ones(T,A);  %% up reserve
    %ReserveDn=ones(T,A);  %% down reserve
    %%------------------------- wind power and PV data ------------------------
    Windmax(:,a)   = xlsread(areaFile{a},3,['B2:B' num2str(T+1)]);     %% theory output of wind power
    PVmax(:,a)     = xlsread(areaFile{a},4,['B2:B' num2str(T+1)]);     %% theory output of PV
    %%----------------------------- tie-line data -----------------------------
    Tieline{a}     = xlsread(areaFile{a},5,['B2:D' num2str(Ntie(a)+1)]);
    % for a=1:A
    %     Tieline{a}=ones(Ntie(a),3);    %% [connected_area, type, flow_max]
    %     Ftie0{a}  =ones(T,Ntie(a));    
    %     Etie{a}   =ones(TD,Ntie(a));       
    % end
    ReserveUp(:,a)  = xlsread(areaFile{a},8,['B2:B' num2str(T+1)]);  %% up reserve
    ReserveDn(:,a)  = xlsread(areaFile{a},8,['C2:C' num2str(T+1)]);  %% down reserve
end
%% save data
save input_data;