%%power distribution in PV, wind power and therma unit generation
for a=1:A
    figure;
    hold on;
%     area(Demand(1:168,a),'FaceColor','g','EdgeColor','g');
    area(sum(Pthermal_F{a}(1:168,:),2)+Pwind_F(1:168,a)+Ppv_F(1:168,a)+sum(Ftie_F{a}(1:168,:),2),'FaceColor','k','EdgeColor','k');
    area(sum(Pthermal_F{a}(1:168,:),2)+Pwind_F(1:168,a)+Ppv_F(1:168,a),'FaceColor','r','EdgeColor','r');
    area(sum(Pthermal_F{a}(1:168,:),2)+Pwind_F(1:168,a),'FaceColor','y','EdgeColor','y');
    area(sum(Pthermal_F{a}(1:168,:),2),'FaceColor','b','EdgeColor','b');
    plot(Ppv_F(1:168,a));
    plot(Pwind_F(1:168,a));
    legend('Demand','PV','Wind','Thermal')
    hold off;
end
