%%read the value of variables
%%use after function optimize();
%%--------------------------- wind power & PV -----------------------------
Pwind_V=value(Pwind);    %% output of wind power 
Ppv_V  =value(Ppv);    %% output of PV 

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