#define CONFIG_REG 0x1A100000
#define INPUT_REG 0x1A100004
#define OUTPUT_REG 0x1A100008

#define CONFIG_READY 0x0080
#define CONFIG_INIT 0x0002
#define CONFIG_GO 0x0001


 //256 i
int test_inputs[] =
{
  0x02FA0BE8,  0x02FA0BE8,  0x02FA0BE8,  0x02FA0BE8,  0x02FA0BE8,  0x02FA0BE8,  0x02FA0BE8,  0x02FA0BE8,
  0x02FA0BE8,  0x002B8BA6,  0xFE36C5A7,  0xFD317FBE,  0xFCDA6870,  0xFD269CD4,  0xFD9379F6,  0xFE0B3A01,
  0xFE2BE2BE,  0xFE4C8B7B,  0xFE62514E,  0xFE4C8B7B,  0xFE4C8B7B,  0xFE36C5A7,  0xFE0B3A01,  0xFDDFAE5A,
  0xFDD4CB70,  0xFDEA9143,  0xFDF5742D,  0xFE2BE2BE,  0xFE005717,  0xFE0B3A01,  0xFE0B3A01,  0xFE41A891,
  0xFE781722,  0xFE98BFDF,  0xFE576E65,  0xFE36C5A7,  0xFE2BE2BE,  0xFE576E65,  0xFE8DDCF5,  0xFEAE85B2,
  0xFE82FA0B,  0xFE576E65,  0xFE36C5A7,  0xFE4C8B7B,  0xFE4C8B7B,  0xFE576E65,  0xFE6D3438,  0xFE6D3438,
  0xFE781722,  0xFE82FA0B,  0xFE82FA0B,  0xFE98BFDF,  0xFECF2E6F,  0xFEFABA16,  0xFF059D00,  0xFEE4F443,
  0xFEAE85B2,  0xFE62514E,  0xFE62514E,  0xFE6D3438,  0xFE781722,  0xFEA3A2C9,  0xFECF2E6F,  0xFEE4F443,
  0xFF107FEA,  0xFEFABA16,  0xFEE4F443,  0xFEE4F443,  0xFEEFD72D,  0xFF3128A7,  0xFF3128A7,  0xFF3C0B91,
  0xFF51D164,  0xFF5CB44E,  0xFF679737,  0xFF5CB44E,  0xFF727A21,  0xFF883FF5,  0xFF7D5D0B,  0xFF883FF5,
  0xFFA8E8B2,  0xFFBEAE85,  0xFFD47459,  0xFFDF5742,  0xFFDF5742,  0xFFEA3A2C,  0x0020A8BD,  0x004C3464,
  0x00366E90,  0x0020A8BD,  0x0020A8BD,  0x00366E90,  0x00366E90,  0x0057174D,  0x0057174D,  0x0041517A,
  0x0020A8BD,  0x002B8BA6,  0x004C3464,  0x0061FA37,  0x006CDD21,  0x00366E90,  0x002B8BA6,  0x002B8BA6,
  0x0015C5D3,  0x0015C5D3,  0x00000000,  0xFFF51D16,  0xFFC9916F,  0xFFD47459,  0xFFBEAE85,  0xFFBEAE85,
  0xFFB3CB9B,  0xFF9E05C8,  0xFF883FF5,  0xFF7D5D0B,  0xFF727A21,  0xFF5CB44E,  0xFF51D164,  0xFF5CB44E,
  0xFF5CB44E,  0xFF5CB44E,  0xFF679737,  0xFF5CB44E,  0xFF51D164,  0xFF3C0B91,  0xFF2645BD,  0xFF3128A7,
  0xFF3128A7,  0xFF46EE7A,  0xFF3128A7,  0xFF2645BD,  0xFF2645BD,  0xFF059D00,  0xFF059D00,  0xFEE4F443,
  0xFECF2E6F,  0xFEB9689C,  0xFEA3A2C9,  0xFEC44B86,  0xFEAE85B2,  0xFEA3A2C9,  0xFE8DDCF5,  0xFE6D3438,
  0xFE82FA0B,  0xFE8DDCF5,  0xFE98BFDF,  0xFE8DDCF5,  0xFE8DDCF5,  0xFE98BFDF,  0xFE781722,  0xFE781722,
  0xFE4C8B7B,  0xFE4C8B7B,  0xFE2BE2BE,  0xFE41A891,  0xFE36C5A7,  0xFE41A891,  0xFE36C5A7,  0xFE20FFD4,
  0xFE161CEA,  0xFE161CEA,  0xFDF5742D,  0xFE161CEA,  0xFE36C5A7,  0xFE41A891,  0xFE576E65,  0xFE62514E,
  0xFE4C8B7B,  0xFE62514E,  0xFE62514E,  0xFE6D3438,  0xFE8DDCF5,  0xFE8DDCF5,  0xFE82FA0B,  0xFE98BFDF,
  0xFE98BFDF,  0xFE6D3438,  0xFE6D3438,  0xFE41A891,  0xFE41A891,  0xFE36C5A7,  0xFE576E65,  0xFE576E65,
  0xFE62514E,  0xFE576E65,  0xFE576E65,  0xFE576E65,  0xFE6D3438,  0xFE82FA0B,  0xFE82FA0B,  0xFE4C8B7B,
  0xFE161CEA,  0xFDDFAE5A,  0xFDF5742D,  0xFDF5742D,  0xFDF5742D,  0xFDDFAE5A,  0xFDC9E886,  0xFDB422B3,
  0xFD9E5CDF,  0xFD67EE4F,  0xFD269CD4,  0xFD05F417,  0xFD1BB9EB,  0xFD9379F6,  0xFE41A891,  0xFEDA1159,
  0xFF3128A7,  0xFF9E05C8,  0x0015C5D3,  0x00A34BB1,  0x0130D190,  0x017D05F4,  0x0125EEA6,  0x0061FA37,
  0xFEAE85B2,  0xFC62A866,  0xF9F6225C,  0xF837CAED,  0xF6BAC4F9,  0xF55384D9,  0xF422B348,  0xF38A4A80,
  0xF3333333,  0xF353DBF0,  0xF3AAF33E,  0xF42D9632,  0xF49A7353,  0xF532DC1B,  0xF62D3F1B,  0xF7484AD8,
  0xF7EB9689,  0xF8172230,  0xF8172230,  0xF842ADD7,  0xF8791C68,  0xF8A4A80E,  0xF8DB169F,  0xF9322DED,
  0xF9942824,  0xF9EB3F72,  0xFA62FF7D,  0xFAA450F7,  0xFB112E18,  0xFB684566,  0xFBA996E0,  0xFC0B9118,
  0xFC4CE292,  0xFCA3F9E0,  0xFCE54B5A,  0xFD52287B,  0xFDBF059D,  0xFE4C8B7B,  0xFEAE85B2,  0xFF3C0B91
};

int hid_coeffs[] = {
  (int) 0xC22E4571, (int) 0x6B12F75B, (int) 0xE34F40F4, (int) 0xEF6F823E
};

int lod_coeffs[] = {
  (int) 0xEF6F823E, (int) 0x1CB0BF0B, (int) 0x6B12F75B, (int) 0x3DD1BA8E
};

void apply_filter(int* filtred_signal, int input_signal[],
  unsigned int input_length, int filter_bank[], unsigned int filter_length) {
    
  int* signal_window = (int*) 0x00100408;
  unsigned int edge_index;

  for(edge_index = 1; edge_index < (input_length+filter_length); edge_index = edge_index + 2) {
    signal_window[0] = input_signal[edge_index];
    signal_window[1] = input_signal[edge_index-1];
    int tmp = 0; unsigned int i;
    for(i = 0; i < filter_length; i = i + 1) {
      tmp  = tmp + signal_window[i] * filter_bank[i];
    } 
    filtred_signal[edge_index] = tmp;
    for(i = filter_length - 1; i >= 1; i = i - 1) {
      signal_window[i] = signal_window[i-1];
    }
    for(i = filter_length - 1; i >= 1; i = i - 1) {
      signal_window[i] = signal_window[i-1];
    }
  }
  return;
}

void wavelet_analysis(int* dwt_coeffs, int decomposition_level,
  unsigned int signal_length, unsigned int filter_length) {
  
  int* cur_inputs = &test_inputs[0];
  int* detail_coeffs = (int*) 0x00100200;
  int* approx_coeffs = (int*) 0x00100300;
  int dec_idx; unsigned int i; unsigned int coeffs_length; unsigned int prev_coeffs = 0;

  int cur_inputs_length = signal_length;
  for(dec_idx = 0; dec_idx < decomposition_level; dec_idx = dec_idx + 1) {
    
    apply_filter(dwt_coeffs, cur_inputs, cur_inputs_length, hid_coeffs, filter_length);
    coeffs_length = ((cur_inputs_length + filter_length - 1) >> 1);
    for(i = 0; i < coeffs_length; i = i + 1) {
      dwt_coeffs[prev_coeffs+i] = detail_coeffs[i];
    }

    apply_filter(approx_coeffs, cur_inputs, cur_inputs_length, lod_coeffs, filter_length);
    prev_coeffs = prev_coeffs + coeffs_length;
    for(i = 0; i < coeffs_length; i = i + 1) {
      cur_inputs[i] = approx_coeffs[i];
    }
  
    cur_inputs_length = coeffs_length;
  }

  for(i = 0; i < coeffs_length; i = i + 1) {
    dwt_coeffs[prev_coeffs+i] = approx_coeffs[i];
  }
}

int main()
{
  // int bkeeping[] = {129, 66, 34, 34};
  // int decomposition_level = 1;
  // int* dwt_coeffs = (int*) 0x00100000;

  // int total_coeff_count = 0; int dec_idx;
  // for(dec_idx = 0; dec_idx < (decomposition_level+1); dec_idx = dec_idx + 1) {
  //   total_coeff_count = total_coeff_count + bkeeping[dec_idx]; 
  // }
  // wavelet_analysis(dwt_coeffs, decomposition_level, 256, 4);
  int* detail_coeffs = (int*) 0x00100000;
  int* approx_coeffs = (int*) 0x00100204;
  apply_filter(detail_coeffs, test_inputs, 256, hid_coeffs, 4);
  apply_filter(approx_coeffs, test_inputs, 256, lod_coeffs, 4);

  // duv_put_configs
  *((int*)CONFIG_REG) = 0x0300; //000_00011_0_00_00_0_0_0;  

  // duv_put_init 
  // *((int*)CONFIG_REG) = 0x0302; //000_00011_0_00_00_0_1_0;

  // duv_put_coeffs 0x1F60; //000_11111_0_11_00_0_0_0; 256i_4f_d1
  // *((int*)INPUT_REG) = 0x00005A94;
  // *((int*)INPUT_REG) = 0xFFFFD2BB;
  // *((int*)INPUT_REG) = 0xFFFA940C;
  // *((int*)INPUT_REG) = 0x000132BC;
  // *((int*)INPUT_REG) = 0x002BDE00;
  // *((int*)INPUT_REG) = 0xFFF8B8C0;
  // *((int*)INPUT_REG) = 0xFF1CA9D7;
  // *((int*)INPUT_REG) = 0x002C8F34;
  // *((int*)INPUT_REG) = 0x0331A6E7;
  // *((int*)INPUT_REG) = 0xFF8CF9AD;
  // *((int*)INPUT_REG) = 0xF602DB0A;
  // *((int*)INPUT_REG) = 0x03EEAB97;
  // *((int*)INPUT_REG) = 0x146D8457;
  // *((int*)INPUT_REG) = 0xF9153294;
  // *((int*)INPUT_REG) = 0xC327F788;
  // *((int*)INPUT_REG) = 0x60D5CF90;
  // *((int*)INPUT_REG) = 0xCD2B1361;
  // *((int*)INPUT_REG) = 0xFB931259;
  // *((int*)INPUT_REG) = 0x0892E68A;
  // *((int*)INPUT_REG) = 0x04237DA1;
  // *((int*)INPUT_REG) = 0xFF607190;
  // *((int*)INPUT_REG) = 0xFC0683A1;
  // *((int*)INPUT_REG) = 0x00667320;
  // *((int*)INPUT_REG) = 0x019F103F;
  // *((int*)INPUT_REG) = 0xFFE87733;
  // *((int*)INPUT_REG) = 0xFF80D48C;
  // *((int*)INPUT_REG) = 0x00038DB5;
  // *((int*)INPUT_REG) = 0x001BEE11;
  // *((int*)INPUT_REG) = 0xFFFF1475;
  // *((int*)INPUT_REG) = 0xFFFC6A05;
  // *((int*)INPUT_REG) = 0x00001A1E;
  // *((int*)INPUT_REG) = 0x00003442;

  // *((int*)INPUT_REG) = 0x00003442;
  // *((int*)INPUT_REG) = 0xFFFFE5E1;
  // *((int*)INPUT_REG) = 0xFFFC6A05;
  // *((int*)INPUT_REG) = 0x0000EB8A;
  // *((int*)INPUT_REG) = 0x001BEE11;
  // *((int*)INPUT_REG) = 0xFFFC724A;
  // *((int*)INPUT_REG) = 0xFF80D48C;
  // *((int*)INPUT_REG) = 0x001788CC;
  // *((int*)INPUT_REG) = 0x019F103F;
  // *((int*)INPUT_REG) = 0xFF998CDF;
  // *((int*)INPUT_REG) = 0xFC0683A1;
  // *((int*)INPUT_REG) = 0x009F8E6F;
  // *((int*)INPUT_REG) = 0x04237DA1;
  // *((int*)INPUT_REG) = 0xF76D1975;
  // *((int*)INPUT_REG) = 0xFB931259;
  // *((int*)INPUT_REG) = 0x32D4EC9E;
  // *((int*)INPUT_REG) = 0x60D5CF90;
  // *((int*)INPUT_REG) = 0x3CD80877;
  // *((int*)INPUT_REG) = 0xF9153294;
  // *((int*)INPUT_REG) = 0xEB927BA8;
  // *((int*)INPUT_REG) = 0x03EEAB97;
  // *((int*)INPUT_REG) = 0x09FD24F5;
  // *((int*)INPUT_REG) = 0xFF8CF9AD;
  // *((int*)INPUT_REG) = 0xFCCE5918;
  // *((int*)INPUT_REG) = 0x002C8F34;
  // *((int*)INPUT_REG) = 0x00E35628;
  // *((int*)INPUT_REG) = 0xFFF8B8C0;
  // *((int*)INPUT_REG) = 0xFFD421FF;
  // *((int*)INPUT_REG) = 0x000132BC;
  // *((int*)INPUT_REG) = 0x00056BF3;
  // *((int*)INPUT_REG) = 0xFFFFD2BB;
  // *((int*)INPUT_REG) = 0xFFFFA56B;


  //4f 000_00011_0_11_00_0_0_0; 0x0360
  // *((int*)INPUT_REG) = 0xC22E4571;
  // *((int*)INPUT_REG) = 0x6B12F75B;
  // *((int*)INPUT_REG) = 0xE34F40F4;
  // *((int*)INPUT_REG) = 0xEF6F823E;

  // *((int*)INPUT_REG) = 0xEF6F823E;
  // *((int*)INPUT_REG) = 0x1CB0BF0B;
  // *((int*)INPUT_REG) = 0x6B12F75B;
  // *((int*)INPUT_REG) = 0x3DD1BA8E;
  

  // duv_wait_init_finish
  // while((*((int*)CONFIG_REG) & CONFIG_INIT)) {}

  // // duv_put_go
  // *((int*)CONFIG_REG) = 0x0301;

  // // duv_reset_r_addr
  // *((int*)CONFIG_REG) = 0x0304;

  // // duv_put_signal
  // int input_idx;
  // for(input_idx = 0; input_idx < 256; input_idx = input_idx + 1) {
  //   *((int*)INPUT_REG) = test_inputs[0];
  // }

  // // duv_wait_go_finish
  // while((*((int*)CONFIG_REG) & CONFIG_GO)) {}
  
  // // duv_read_outputs
  // int output_data = 0;
  // while(1){
  //   output_data = *((int*)OUTPUT_REG);
  //   if(!(*((int*)CONFIG_REG) & CONFIG_READY))
  //     break;
  // }

  return 0;
}
