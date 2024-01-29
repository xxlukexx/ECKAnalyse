function [mainBuffer, timeBuffer] = etTobii2ECK(tobiiData)

% convert times to microsecs
microSecs1      =   uint64(tobiiData(:, 1) * 1000000);
microSecs2      =   uint64(tobiiData(:, 2)); 
zBlank          =   zeros(size(microSecs1, 1), 1);
timeBuffer      =   [microSecs1 + microSecs2, zBlank];

% transform gaze data
leftX           =   tobiiData(:, 3);
leftY           =   tobiiData(:, 4);
rightX          =   tobiiData(:, 5);
rightY          =   tobiiData(:, 6);
leftPosX        =   tobiiData(:, 7);
leftPosY        =   tobiiData(:, 8);
rightPosX       =   tobiiData(:, 9);
rightPosY       =   tobiiData(:, 10);
leftVal         =   tobiiData(:, 11);
rightVal        =   tobiiData(:, 12);
leftPupil       =   tobiiData(:, 13);
rightPupil      =   tobiiData(:, 14);
leftPosZ        =   tobiiData(:, 15);
rightPosZ       =   tobiiData(:, 16);

mainBuffer = [...
                leftPosX,...        ' 1. eye pos 3d.x UCS
                leftPosY,...        ' 2. eye pos 3d.y UCS
                leftPosZ,...        ' 3. eye pos 3d.z UCS
                zBlank,...          ' 4. eye pos 3d.x TBCS 
                zBlank,...          ' 5. eye pos 3d.y TBCS
                zBlank,...          ' 6. eye pos 3d.z TBCD
                leftX,...           ' 7. gaze 2d.x ADCS
                leftY,...           ' 8. gaze 2d.y ADCS
                zBlank,...          ' 9. gaze 3d.x UCS
                zBlank,...          ' 10. gaze 3d.y UCS
                zBlank,...          ' 11. gaze 3d.z UCS
                leftPupil,...       ' 12. pupil mm
                leftVal,...         ' 13. validity
                rightPosX,...       ' 14. eye pos 3d.x UCS
                rightPosY,...       ' 15. eye pos 3d.y UCS
                rightPosZ,...       ' 16. eye pos 3d.z UCS
                zBlank,...          ' 17. eye pos 3d.x TBCS 
                zBlank,...          ' 18. eye pos 3d.y TBCS
                zBlank,...          ' 19. eye pos 3d.z TBCD
                rightX,...          ' 20. gaze 2d.x ADCS
                rightY,...          ' 21. gaze 2d.y ADCS
                zBlank,...          ' 22. gaze 3d.x UCS
                zBlank,...          ' 23. gaze 3d.y UCS
                zBlank,...          ' 24. gaze 3d.z UCS
                rightPupil,...      ' 25. pupil mm
                rightVal,...        ' 26. validity
            ];
end