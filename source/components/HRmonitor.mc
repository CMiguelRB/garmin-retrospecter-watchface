import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.ActivityMonitor;


class HRmonitor extends WatchUi.Drawable {

    hidden var mWmin;
    hidden var mWmax;
    hidden var mWdiff;
    hidden var mHmax;
    hidden var mHmin;
    hidden var mHdiff;

    function initialize(params as Object) {
        Drawable.initialize(params);

        mWmin = 12;
        mWmax = Settings.get("width") - 12;
        mWdiff = mWmax - mWmin;
        mHmax = 55;
        mHmin = 35;
        mHdiff = mHmax - mHmin;
    }

    function draw(dc){

        //Draw HR icon and current HR value
        drawCurrentHr(dc);

        //Draw HR chart        

        var points = getHrPoints(Settings.get("height")) as Array<Array>;

        var polyPoints = points[1] as Array<Array>;
        var linePoints = points[0] as Array<Number>;

        dc.setColor(themeColor(Color.PRIMARY), Graphics.COLOR_TRANSPARENT);

        dc.setColor(themeColor(Color.PRIMARY), Graphics.COLOR_TRANSPARENT);

        dc.fillPolygon(polyPoints);

        dc.setPenWidth(3);

        dc.setColor(themeColor(Color.SECONDARY_1), Graphics.COLOR_TRANSPARENT);

        for(var i = 0; i<linePoints.size();i++){
            if(linePoints[i] == null){
                continue;
            }
            var point = linePoints[i] as Array<Number>;
            dc.drawLine(point[0], point[1], point[2], point[3]);
        }
    }

    hidden function getHrPoints(height){
        var hrIterator = ActivityMonitor.getHeartRateHistory(new Time.Duration(7200), false);

        //Gather samples data
        var samples = {};                            // get the previous HR
        var sample = hrIterator.next();
        var hrMax = hrIterator.getMax();
        var hrMin = hrIterator.getMin();
        var counter = 0;
        var innerCounter = 0;
        while (sample != null) {
            if(counter % 5 == 0){
                if (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                        samples[innerCounter] = sample.heartRate;
                }else{
                    samples[innerCounter] = null;
                }    
                innerCounter++;
            }   
            sample = hrIterator.next();
            counter++;                                                     // null check
        }     

        //Define line x length
        var xLength = mWdiff / innerCounter;

        //Get firtst Y transformed point
        sample = samples[0];
        var startYLine = transformYValue(sample, hrMax, hrMin, height);
        
        //Initialize coordinates
        var startPoint = [mWmin, startYLine];
        var endPoint = [(mWmin+xLength), null];
        
        //initialize arrays
        var polyPoints = new [(innerCounter*2)];
        var linePoints = new [(innerCounter-1)];  

        //Loop samples
        for(var i = 0; i<innerCounter-1; i++){
            var currentSample = samples[i];
            var nextSample = samples[(i+1)];
            if(currentSample == null){
                linePoints[i] = null;
                startPoint[0] = endPoint[0];
                endPoint[0] = endPoint[0] + xLength;
                polyPoints[i*2] = [startPoint[0]-xLength, height];
                polyPoints[i*2+1] = [endPoint[0]-xLength, height];
                continue;           
            }
            endPoint[1] = transformYValue(nextSample, hrMax, hrMin, height);                     
            linePoints[i] = [startPoint[0], startPoint[1], endPoint[0], endPoint[1]];            
            polyPoints[i*2] = [startPoint[0], startPoint[1]];
            polyPoints[i*2+1] = [endPoint[0], endPoint[1]];
            startPoint[0] = endPoint[0];
            startPoint[1] = endPoint[1];
            endPoint[0] = endPoint[0] + xLength;
        }

        //Finish polygon
        polyPoints[(innerCounter*2)-2] = [endPoint[0]-xLength, height];
        polyPoints[(innerCounter*2)-1] = [mWmin, height];

        return [linePoints, polyPoints];
    }

    hidden function transformYValue(sample, hrMin, hrMax, height){
        var hrDiff = hrMax - hrMin;
        var yLineConv;
        if(sample != null){
            var hrHrMinDiff = sample.toFloat() - hrMin.toFloat();
            yLineConv =  (hrHrMinDiff / hrDiff.toFloat() * mHdiff + mHmin).toFloat();
        }else{
            yLineConv = mHmax;
        } 
        yLineConv = height - yLineConv;
        return yLineConv;
    }

    hidden function drawCurrentHr(dc){
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var currentHr = Activity.getActivityInfo().currentHeartRate;

        if(currentHr == null){
            currentHr = "--";
        }else{
            currentHr = currentHr.format("%i");
        }

        dc.drawText(dc.getWidth() / 2 - 25, dc.getHeight()/2 + dc.getHeight()/4 + 15, Settings.resource(Rez.Fonts.Icons), "f", Graphics.TEXT_JUSTIFY_CENTER);

        var charArray = currentHr.toCharArray();
        var hrX = dc.getWidth() / 2;
        var hrY = dc.getHeight()/2 + 130;
        var offset = 0;

        for(var i = 0; i < charArray.size(); i++ ){
            dc.drawText(
                hrX + offset,
                hrY,
                Settings.resource(Rez.Fonts.Date),
                charArray[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );  
            offset += 15; 
        } 
    }
}