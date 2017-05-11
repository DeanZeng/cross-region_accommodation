%display results
%% read values of variables
%%--------------------------- wind power & PV -----------------------------
Pwind_V=value(Pwind);    %% output of wind power 
Ppv_V  =value(Ppv);      %% output of PV 

%%--------------------------- thermal unit --------------------------------
Pthermal_V=cell(1,A);          %% output of thermal unit
onoff_V=cell(1,A);           %% on_off status;
startup_V=cell(1,A);              %% start up indicator
shutdown_V=cell(1,A);            %% shut down indicator
for a=1:A
    Pthermal_V{a} = value(Pthermal{a});
    onoff_V{a}=value(onoff{a});
    startup_V{a}  = value(startup{a});
    shutdown_V{a} = value( shutdown{a});
end

%%---------------------------- tie lines ----------------------------------
Ftie_V=cell(1,A);
for a=1:A
    Ftie_V{a} = value( Ftie{a});
end

minLang_V=cell(1,A);
for a=1:A
    minLang_V{a}=value(minLang{a});
end
%% plot
for a=1:A
    %%------------------------ thermal unit -------------------------------
    figure;
    stairs(Pthermal_V{a});
    title(['thermal unit output in area' num2str(a)]);
    %%------------------------------- wind ------------------------------------
    figure;
    hold on;
    stairs(Windmax(:,a));
    stairs(Pwind_V(:,a));
    title(['wind power in area' num2str(a)]);
    hold off;
    %%-------------------------------- PV -------------------------------------
    figure;
    hold on;
    stairs(PVmax(:,a));
    stairs(Ppv_V(:,a));
    title(['PV generation in area' num2str(a)]);
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
                    stairs(Ftie_V{a}(:,la));
                    stairs(Ftie_V{b}(:,lb));
                    legend(['Tie ' num2str(a) '-' num2str(b)],['Tie ' num2str(b) '-' num2str(a)]); 
                    title('tie line power flow');
                    hold off;
                end
            end
        end
    end
end