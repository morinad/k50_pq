// This file contains your Data Connector logic
section K50;

[DataSource.Kind="K50", Publish="K50.Publish"]
shared K50.BI = Value.ReplaceType(K50.Data, FuncType);

FuncType = type function (
     num  as (type text meta [
        Documentation.FieldCaption = "Table number:",
        Documentation.FieldDescription = "Enter number of your K50.BI table.",
        Documentation.SampleValues = {"12345"}
    ]),
    start as (type text meta [
        Documentation.FieldCaption = "Start date:",
        Documentation.FieldDescription = "Enter the first date of your statistics. You can specify date in YYYY-MM-DD format or use dynamic formats: today, yesterday, 69daysAgo.",
        Documentation.SampleValues = {"2020-02-28"}
    ]),
     end as (type text meta [
        Documentation.FieldCaption = "End date:",
        Documentation.FieldDescription = "Enter the last date of your statistics. You can specify date in YYYY-MM-DD format or use dynamic formats: today, yesterday, 69daysAgo.",
        Documentation.SampleValues = {"yesterday"}
    ])
    )
    as table meta [
        Documentation.Name = "K50.BI Function",
        Documentation.LongDescription = "Created to get data from K50.BI service",
        Documentation.Examples = {
        [
            Description = "Returns a list of records from your K50 table",
            Code = "K50.BI(""12345"",""2020-02-20"",""yesterday"")",
            Result = "{[Record1],[Record2],[Record3],...}"
        ],
        [
            Description = "Returns a list of records from your K50 table",
            Code = "K50.BI(""54321"",""69daysAgo"",""today"")",
            Result = "{[Record1],[Record2],[Record3],...}"
        ]
        }
    ];



K50.Data = 
( num as text,   start as text,  end as text)=>
let
get = [#"from"=date_func(start), #"to"=date_func(end), #"apiKey"= Extension.CurrentCredential()[Key]],  
web1 = web_func(get,num),
web2=retry_func(web1, get, num, 5),
web3=retry_func(web2, get, num, 7),
web4=retry_func(web3, get, num, 9),
web5=retry_func(web4, get, num, 10),
web6=retry_func(web5, get, num, 10),
web7=retry_func(web6, get, num, 10),
web8=retry_func(web7, get, num, 10),
web9=retry_func(web8, get, num, 10),
web10=retry_func(web9, get, num, 10),
web11=retry_func(web10, get, num, 10),
web12=retry_func(web11, get, num, 10),
web13=retry_func(web12, get, num, 10),
web14=retry_func(web13, get, num, 10),
web15=retry_func(web14, get, num, 10),
web16=retry_func(web15, get, num, 10),
web17=retry_func(web16, get, num, 10),
web18=retry_func(web17, get, num, 10),
web19=retry_func(web18, get, num, 10),
web20=retry_func(web19, get, num, 10),
web21=retry_func(web20, get, num, 10),
web22=retry_func(web21, get, num, 10),
web23=retry_func(web22, get, num, 10),
web=retry_func(web23, get, num, 10),


total = try web[total] otherwise null,
error_message = try web[message] otherwise null,
state = try web[state] otherwise null,

out = if error_message <> null then error_message 
      else if state = "pending" then pendText 
      else if total = null then wtfText
      else try finalFunc(total,get,num) otherwise wtf2Text
in out;

pendText =  "The response timeout is exceeded. Your report will be available in a minute!";
wtfText =  "Unknown error. Try again in a minute!";
wtf2Text =  "Unknown error.";

finalFunc = (total,get,num)=>
let
    final = Number.RoundDown( total / 10000 ),
    spisok = {0..final},
    otstup = Table.FromList(spisok, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    offset = Table.TransformColumns(otstup, {{"Column1", each _ * 10000, type number}}),
    change = Table.TransformColumnTypes(offset,{{"Column1", type text}}),
    binary = Table.AddColumn(change, "binary", each Web.Contents("https://bi.k50.ru/", [Query = get &[offset=[Column1], limit ="10000"] , RelativePath="api/table/" & num  & "/getData", ManualStatusHandling = {404, 400,500}])),
    json = Table.AddColumn(binary, "json", each Json.Document([binary])[data]),
    data = Table.ExpandListColumn(json, "json"),
    remove = Table.RemoveColumns(data,{"Column1", "binary"})
in remove; 


web_func= (get,num)=>
       Json.Document(Web.Contents("https://bi.k50.ru/", [Query = get, RelativePath= "api/table/" & num  & "/getData", ManualStatusHandling = {404, 400,500,401,402,403,501,502,503,504,505}]));
   

date_func= (dat)=>
       if dat = "yesterday" then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()) , -1),"yyyy-MM-dd") 
       else if dat = "today" then Date.ToText(Date.From(DateTime.LocalNow()),"yyyy-MM-dd")
       else if (try Number.From(Text.BeforeDelimiter(dat,"daysAgo")) otherwise 0) >0 then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),-1*Number.From(Text.BeforeDelimiter(dat,"daysAgo"))),"yyyy-MM-dd") 
       else dat;


retry_func=(web, get, num, sec)=>
    let
    delay = try Number.From(web[retry_after]) otherwise 0,
    new = if delay>0 then Function.InvokeAfter(()=> web_func(get,num), #duration(0,0,0,sec)) else web
    in new;



// Data Source Kind description
K50 = [
    TestConnection = (dataSourcePath) => { "K50.BI", Json.Document(dataSourcePath)[num],Json.Document(dataSourcePath)[start],Json.Document(dataSourcePath)[end]},
    Authentication = [
        
         Key = []

    ],
    Label = "K50 Connection"
];


// Data Source UI publishing description
K50.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = { "K50 Connector", "K50 Help" },
    LearnMoreUrl = "https://www.youtube.com/channel/UCqSLNYLN_3mf6nA1Xf7fu1g/",
    SourceImage = K50.Icons,
    SourceTypeImage = K50.Icons
];

K50.Icons = [
    Icon16 = { Extension.Contents("K5016.png"), Extension.Contents("K5020.png"), Extension.Contents("K5024.png"), Extension.Contents("K5032.png") },
    Icon32 = { Extension.Contents("K5032.png"), Extension.Contents("K5040.png"), Extension.Contents("K5048.png"), Extension.Contents("K5064.png") }
];
