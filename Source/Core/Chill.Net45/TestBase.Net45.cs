﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Chill
{
#if NET45
    public partial class TestBase
    {
        partial void GetBuiltInContainer(ref object attribute)
        {
            attribute = new ChillContainerAttribute(typeof (TinyIocChillContainer));
        }
    }
#endif
}