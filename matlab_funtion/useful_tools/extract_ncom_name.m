function string_struct = extract_ncom_name(name_string)

    letter_pat = extract(name_string,lettersPattern);
    digit_pat = extract(name_string,digitsPattern);
    
    string_struct.fldname = cell2mat(letter_pat(1));
    string_struct.igrd = str2num(cell2mat(digit_pat(4)));
    string_struct.jgrd = str2num(cell2mat(digit_pat(5)));
    string_struct.nest = str2num(cell2mat(digit_pat(3)));
    string_struct.datestr_in = cell2mat(digit_pat(6));
    string_struct.timetag = cell2mat(digit_pat(7));
    string_struct.appd = ['_',cell2mat(letter_pat(end))];

    if strcmpi(string(letter_pat(2)), "sfc")
        string_struct.nlev = 1;
        string_struct.isface = false;
    elseif strcmpi(string(letter_pat(2)), "mod")
        string_struct.nlev = 100;
        if str2num(cell2mat(digit_pat(2))) == 100
            string_struct.isface = false;
        elseif str2num(cell2mat(digit_pat(2))) == 101
            string_struct.isface = true;
        else
            error("data file name string mismatch on vertical");
        end
    else
        error("data file name string mismatch");
    end

end