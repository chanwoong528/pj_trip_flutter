const OVERALL_DATA = {
  tourName: "오키나와", // user should input this can be modified, like "의정부 투어", "일본 오사카 투어", "미국 뉴욕 투어"
  latitude: 26.2123,
  longitude: 127.6806,

  travelList: [
    {
      travelName: "1일차", //user should input this: can be modified, like "1일차", "2일차", "3일차" or "오전", "오후" or "아침", "점심", "저녁"
      tripList: [
        {
          order: 0,
          name: "신세계백화점 의정부점",
          latitude: 12.9716,
          longitude: 77.5946,
          address: "경기 의정부시 평화로 525 의정부민자역사",
          navigationUrl: "https://map.kakao.com/link/place/1234567890",
        },
        {
          order: 1,
          name: "의정부 제일시장",
          latitude: 12.9716,
          longitude: 77.5946,
          address: "경기 의정부시 평화로 525 의정부민자역사",
          navigationUrl: "https://map.kakao.com/link/place/1234567890",
        },
      ],
    },
    {
      travelName: "2일차", // can be fixed, like "1일차", "2일차", "3일차" or "오전", "오후" or "아침", "점심", "저녁"
      tripList: [
        {
          order: 0,
          name: "의정부 메가박스",
          latitude: 12.9716,
          longitude: 77.5946,
          address: "경기 의정부시 평화로 525 의정부민자역사",
          navigationUrl: "https://map.kakao.com/link/place/1234567890",
        },
        {
          order: 1,
          name: "의정부 문화원",
          latitude: 12.9716,
          longitude: 77.5946,
          address: "경기 의정부시 평화로 525 의정부민자역사",
          navigationUrl: "https://map.kakao.com/link/place/1234567890",
        },
      ],
    },
  ],
};
