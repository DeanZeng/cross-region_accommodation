%% rolling calculation per week
RollNum=364;         %%滚动次数
RollStart=(1:24:8737)';       %%滚动周期起始时间
%% full period input data
in_full = load('input_data.mat', 'in');
%%------------------------ initialization ---------------------------------
in_full = in_full.in;
in    = in_full;
%%------------ system data
in.T=0;                      %% time horizons
in.TD=0;                     %% number of days
T=in.T; A=in.A; TD=in.TD;
%%------------- area data
for a=1:in.A
    in.area(a).Onoff_t0=zeros(1,in.area(a).Nunit);       %% initial status at t=0
    in.area(a).Pthermal_t0=zeros(1,in.area(a).Nunit);    %% initial output at t=0
    in.area(a).On_t0=zeros(1,in.area(a).Nunit);          %% length of time unit g has to be on at the beginning
    in.area(a).Off_t0=zeros(1,in.area(a).Nunit);         %% length of time unit g has to be off at the beginning
    in.area(a).Demand=[];        %% demand
    in.area(a).Windmax=[];      %% theory output of wind power
    in.area(a).PVmax  = [];      %% theory output of PV
    in.area(a).Ftie0=[];          %% fixed power flow
    in.area(a).Etie =[];          %% exchage energy each day
    in.area(a).ReserveUp=[];      %% up reserve
    in.area(a).ReserveDn=[];      %% down reserve
end
%%-------------- results
Pwind_F=zeros(T,A);    %% output of wind power 
Ppv_F  =zeros(T,A);      %% output of PV 
Pthermal_F=cell(1,A);          %% output of thermal unit
onoff_F=cell(1,A);           %% on_off status;
startup_F=cell(1,A);              %% start up indicator
shutdown_F=cell(1,A);            %% shut down indicator
Ftie_F=cell(1,A);

%% roll up
tic;
for roll=1:RollNum
    %%input the rth rolling period data
    for a=1:A
        in.T=RollStart(roll+1)-RollStart(roll);
        if roll==1
            in.area(a).Onoff_t0=in_full.area(a).Onoff_t0;       
            in.area(a).Pthermal_t0=in_full.area(a).Pthermal_t0;   
            in.area(a).On_t0=in_full.area(a).On_t0;         
            in.area(a).Off_t0=in_full.area(a).Off_t0;       
        else
            in.area(a).Onoff_t0=out.area(a).onoff(in.T,:);      
            in.area(a).Pthermal_t0=out.area(a).Pthermal(in.T);    
            [in.area(a).On_t0,in.area(a).Off_t0] = getOnoff_t0(out.area(a).onoff,in.area(a).Minup,in.area(a).Mindown);       
        end
        in.area(a).Demand    = in_full.area(a).Demand(RollStart(roll):RollStart(roll+1)-1,:);        
        in.area(a).Windmax   = in_full.area(a).Windmax(RollStart(roll):RollStart(roll+1)-1,:); 
        in.area(a).PVmax     = in_full.area(a).PVmax(RollStart(roll):RollStart(roll+1)-1,:);  
        in.area(a).ReserveUp = in_full.area(a).ReserveUp(RollStart(roll):RollStart(roll+1)-1,:);      %% up reserve
        in.area(a).ReserveDn = in_full.area(a).ReserveDn(RollStart(roll):RollStart(roll+1)-1,:);      %% dowen reserve
    end

    %%solution
    out=multi_area_accommodation(in);
    %%results
    for a=1:A
        Pwind_F(RollStart(roll):RollStart(roll+1)-1,a)       = out.area(a).Pwind;    %% output of wind power 
        Ppv_F(RollStart(roll):RollStart(roll+1)-1,a)         = out.area(a).Ppv;      %% output of PV 
        Pthermal_F{a}(RollStart(roll):RollStart(roll+1)-1,:) = out.area(a).Pthermal;
        onoff_F{a}(RollStart(roll):RollStart(roll+1)-1,:)    = out.area(a).onoff;
        startup_F{a}(RollStart(roll):RollStart(roll+1)-1,:)  = out.area(a).startup;
        shutdown_F{a}(RollStart(roll):RollStart(roll+1)-1,:) = out.area(a).shutdown;
        Ftie_F{a}(RollStart(roll):RollStart(roll+1)-1,:)     = out.area(a).Ftie;
    end
    roll
    toc;
end
%% save resluts
save results.mat Pwind_F Ppv_F Pthermal_F onoff_F startup_F shutdown_F Ftie_F;
%% display results
for a=1:A
    %%------------------------ thermal unit -------------------------------
    figure;
    stairs(Pthermal_F{a}(1:168,:));
    title(['thermal unit output in area' num2str(a)]);
    %%------------------------------- wind ------------------------------------
    figure;
    hold on;
    stairs(Windmax(1:168,a));
    stairs(Pwind_F(1:168,a));
    title(['wind power in area' num2str(a)]);
    legend('maximum','actual');
    hold off;
    %%-------------------------------- PV -------------------------------------
    figure;
    hold on;
    stairs(PVmax(1:168,a));
    stairs(Ppv_F(1:168,a));
    title(['PV generation in area' num2str(a)]);
    legend('maximum','actual');
    hold off;  
end
%%------------------------------- tie lines -------------------------------
for a=1:A
    for b=a+1:A
        for la=1:Ntie(a)
            for lb=1:Ntie(b)
                if (Tieline{a}(la,1)==b)&&(Tieline{b}(lb,1)==a)
                    figure;
                    hold on;
                    stairs(Ftie_F{a}(1:168,la));
                    stairs(Ftie_F{b}(1:168,lb));
                    legend(['Tie ' num2str(a) '-' num2str(b)],['Tie ' num2str(b) '-' num2str(a)]); 
                    title('tie line power flow');
                    hold off;
                end
            end
        end
    end
end