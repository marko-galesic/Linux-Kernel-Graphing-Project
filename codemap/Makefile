GSOPTS = -sDEVICE=png16m -sPAPERSIZE=a4 -dBATCH -dNOPAUSE 

radarmaker-75dpi.png: RadarMaker.ps
	gs  -r75 $(GSOPTS) -sOutputFile=$@ $<

radarmaker-75-int.png: RadarMaker.ps
	gs  -r75 -dDOINTERPOLATE $(GSOPTS) -sOutputFile=$@ $<

radarmaker-300.png: RadarMaker.ps
	gs  -r300 $(GSOPTS) -sOutputFile=$@ $<

radarmaker-600-bw.png: RadarMaker.ps
	gs  -r600 $(GSOPTS) -sDEVICE=pnggray -sOutputFile=$@ $<

radarmaker-1440.png: RadarMaker.ps
	gs  -r1440 $(GSOPTS) -sOutputFile=$@ $<

